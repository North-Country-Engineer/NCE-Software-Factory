# Define content types for various file extensions
locals {
    content_types = {
        ".html" = "text/html",
        ".css"  = "text/css",
        ".js"   = "application/javascript",
        ".json" = "application/json",
        ".png"  = "image/png",
        ".jpg"  = "image/jpeg",
        ".jpeg" = "image/jpeg",
        ".gif"  = "image/gif",
        ".svg"  = "image/svg+xml",
        ".ico"  = "image/x-icon",
        ".txt"  = "text/plain"
    }
    domains = ["${var.site_domain}"]
}

# Configure AWS provider
provider "aws" {
    region = var.aws_region
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
}

provider "cloudflare" {
    api_token = var.cloudflare_api_token
}



# Create an ACM certificate
resource "aws_acm_certificate" "acm_certificate" {
    domain_name               = var.site_domain
    validation_method         = "DNS"
    subject_alternative_names = local.domains
    lifecycle {
        create_before_destroy = true
    } 
}

data "cloudflare_zone" "this" {
    name = var.site_domain
}

locals {
    validation_records = [
        for dvo in aws_acm_certificate.acm_certificate.domain_validation_options : {
            name    = dvo.resource_record_name
            value   = trimsuffix(dvo.resource_record_value, ".")
            type    = dvo.resource_record_type
            zone_id = data.cloudflare_zone.this.id
        }
    ]
}




# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions_role" {
    name = "github-actions-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Effect = "Allow",
                Principal = {
                    Service = "ec2.amazonaws.com"
                },
                Action = "sts:AssumeRole"
            }
        ]
    })
}

# IAM Policy to allow GitHub Actions to access the S3 bucket
resource "aws_iam_policy" "github_actions_policy" {
    name        = "github-actions-policy"
    description = "Policy for GitHub Actions to access S3 bucket"
    policy      = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Effect = "Allow",
                Action = [
                    "s3:GetObject",
                    "s3:PutObject",
                    "s3:DeleteObject",
                    "s3:ListBucket"
                ],
                Resource = [
                    "arn:aws:s3:::${aws_s3_bucket.site.id}",
                    "arn:aws:s3:::${aws_s3_bucket.site.id}/*"
                ]
            }
        ]
    })
}

# Attach the IAM Policy to the IAM Role
resource "aws_iam_role_policy_attachment" "github_actions_attachment" {
    role       = aws_iam_role.github_actions_role.name
    policy_arn = aws_iam_policy.github_actions_policy.arn
}

# Output the ARN of the GitHub Actions IAM Role
output "github_actions_role_arn" {
    value = aws_iam_role.github_actions_role.arn
}

# Define the S3 bucket for the site. S3 is holding built static files for the next project and sits behind a cloudfront distribution
resource "aws_s3_bucket" "site" {
    bucket = var.site_domain
    force_destroy = true
}

# Configure public access settings for the S3 bucket
resource "aws_s3_bucket_public_access_block" "site" {
    bucket = aws_s3_bucket.site.id

    block_public_acls       = false
    block_public_policy     = false
    ignore_public_acls      = false
    restrict_public_buckets = false
}

# Configure the S3 bucket for static website hosting
resource "aws_s3_bucket_website_configuration" "site" {
    bucket = aws_s3_bucket.site.id

    index_document {
        suffix = "index.html"
    }

    error_document {
        key = "404.html"
    }
}

# Set ownership controls for the S3 bucket
resource "aws_s3_bucket_ownership_controls" "site" {
    bucket = aws_s3_bucket.site.id
    rule {
        object_ownership = "BucketOwnerPreferred"
    }
}

# Set the ACL for the S3 bucket to public-read
resource "aws_s3_bucket_acl" "site" {
    bucket = aws_s3_bucket.site.id

    acl = "public-read"
    depends_on = [
        aws_s3_bucket_ownership_controls.site,
        aws_s3_bucket_public_access_block.site
    ]
}

# Define CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
    comment = "OAI for ${aws_s3_bucket.site.bucket}"
}

# Define the S3 bucket policy to allow public read access and CI actions
resource "aws_s3_bucket_policy" "site" {
    bucket = aws_s3_bucket.site.id

    policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
        {
            Sid: "AllowCloudFrontAccess",
            Effect: "Allow",
            Principal: {
                "AWS": "${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"
            },
            Action: "s3:GetObject",
            Resource: [
                "${aws_s3_bucket.site.arn}/*"
            ]
        },
        {
            Sid: "AllowS3ActionsForCI",
            Effect: "Allow",
            Principal: {
                "AWS": "${aws_iam_role.github_actions_role.arn}"
            },
            Action: [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            Resource: [
            "${aws_s3_bucket.site.arn}",
            "${aws_s3_bucket.site.arn}/*"
            ]
        }
        ]
    })

    depends_on = [
        aws_s3_bucket_public_access_block.site
    ]
}

# Enable versioning for the S3 bucket
resource "aws_s3_bucket_versioning" "site_bucket_versioning" {
    bucket = aws_s3_bucket.site.id
    versioning_configuration {
        status = "Enabled"
    }
}

# Upload static files to the S3 bucket with appropriate content types
resource "aws_s3_object" "static_files" {
    for_each = fileset("${path.module}/static_site/out", "**/*")

    bucket = aws_s3_bucket.site.bucket
    key    = each.value
    source = "${path.module}/static_site/out/${each.value}"
    etag   = filemd5("${path.module}/static_site/out/${each.value}")
    content_type = lookup(local.content_types, regex("\\.[^.]+$", each.value), null)
}

# Validate cert
resource "cloudflare_record" "validation" {
    count = length(local.validation_records)

    zone_id = local.validation_records[count.index].zone_id
    name    = local.validation_records[count.index].name
    type    = local.validation_records[count.index].type
    value   = local.validation_records[count.index].value
    ttl     = 60
    proxied = false

    allow_overwrite = true
}

resource "aws_acm_certificate_validation" "cert_validation" {
    certificate_arn         = aws_acm_certificate.acm_certificate.arn
    validation_record_fqdns = [for record in cloudflare_record.validation : record.hostname]
}


# Cloudfront distribution for S3 bucket
resource "aws_cloudfront_distribution" "site_distribution" {
    depends_on = [
        aws_acm_certificate_validation.cert_validation
    ]

    origin {
        domain_name = aws_s3_bucket.site.bucket_regional_domain_name
        origin_id   = "S3-${aws_s3_bucket.site.bucket}"

        s3_origin_config {
            origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
        }
    }

    enabled             = true
    is_ipv6_enabled     = true
    comment             = "CloudFront distribution for ${var.site_domain}"
    default_root_object = "index.html"

    aliases: [${var.site_domain}]

    default_cache_behavior {
        target_origin_id       = "S3-${aws_s3_bucket.site.bucket}"
        viewer_protocol_policy = "redirect-to-https"
        allowed_methods        = ["GET", "HEAD", "OPTIONS"]
        cached_methods         = ["GET", "HEAD"]

        forwarded_values {
            query_string = false
            cookies {
                forward = "none"
            }
        }

        min_ttl                = 0
        default_ttl            = 86400
        max_ttl                = 31536000
    }

    price_class = "PriceClass_100"

    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }
    custom_error_response {
        error_caching_min_ttl = 0
        error_code            = 403
        response_code         = 200
        response_page_path    = "/index.html"
    }

    custom_error_response {
        error_caching_min_ttl = 0
        error_code            = 404
        response_code         = 200
        response_page_path    = "/index.html"
    }

    viewer_certificate {
        acm_certificate_arn            = aws_acm_certificate.cert.arn
        ssl_support_method             = "sni-only"
        minimum_protocol_version       = "TLSv1.2_2021"
    }
}

//State storage
terraform {
    backend "s3" {
        bucket  = "upstate-tech-pipelines-global-terraform-state"
        key     = "global_state/terraform.tfstate"
        region  = "us-east-1"
    }
}
