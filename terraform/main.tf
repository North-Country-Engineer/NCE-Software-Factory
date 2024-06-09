
locals {
  content_types = {
    ".html" : "text/html",
    ".css" : "text/css",
    ".js" : "text/javascript"
  }
}


provider "aws" {
    region = var.aws_region
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
}

# IAM - Commented out other than for initial stage builds

# IAM Role
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

# IAM Policy
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

# Attach Policy to Role
resource "aws_iam_role_policy_attachment" "github_actions_attachment" {
    role       = aws_iam_role.github_actions_role.name
    policy_arn = aws_iam_policy.github_actions_policy.arn
}

# Output the Role ARN
output "github_actions_role_arn" {
    value = aws_iam_role.github_actions_role.arn
}

//AWS S3
resource "aws_s3_bucket" "site" {
    bucket = var.site_domain
    force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "site" {
    bucket = aws_s3_bucket.site.id

    block_public_acls       = false
    block_public_policy     = false
    ignore_public_acls      = false
    restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "site" {
    bucket = aws_s3_bucket.site.id

    index_document {
        suffix = "index.html"
    }

    error_document {
        key = "404.html"
    }
}

resource "aws_s3_bucket_ownership_controls" "site" {
    bucket = aws_s3_bucket.site.id
    rule {
        object_ownership = "BucketOwnerPreferred"
    }
}

resource "aws_s3_bucket_acl" "site" {
    bucket = aws_s3_bucket.site.id

    acl = "public-read"
    depends_on = [
        aws_s3_bucket_ownership_controls.site,
        aws_s3_bucket_public_access_block.site
    ]
}

resource "aws_s3_bucket_policy" "site" {
    bucket = aws_s3_bucket.site.id

    policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Sid       = "PublicReadGetObject",
                Effect    = "Allow",
                Principal = "*",
                Action    = "s3:GetObject",
                Resource  = [
                    aws_s3_bucket.site.arn,
                    "${aws_s3_bucket.site.arn}/*"
                ]
            },
            {
                Sid       = "AllowS3ActionsForCI",
                Effect    = "Allow",
                Principal = {
                    AWS: "${aws_iam_role.github_actions_role.arn}"
                },
                Action    = [
                    "s3:GetObject",
                    "s3:PutObject",
                    "s3:DeleteObject",
                    "s3:ListBucket"
                ],
                Resource  = [
                    aws_s3_bucket.site.arn,
                    "${aws_s3_bucket.site.arn}/*"
                ]
            }
        ]
    })

    depends_on = [
        aws_s3_bucket_public_access_block.site
    ]
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.site.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "static_files" {
    for_each = fileset("${path.module}/static_site/out", "**/*")

    bucket = aws_s3_bucket.site.bucket
    key    = each.value
    source = "${path.module}/static_site/out/${each.value}"
    etag   = filemd5("${path.module}/static_site/out/${each.value}")
    acl    = "public-read"
}

# resource "null_resource" "update_source_files" {
#     provisioner "local-exec" {
#         command     = "aws s3 sync ./static_site/out/ s3://${aws_s3_bucket.site.id} --delete" 
#     }
# }

// Cloudfront distribution for S3 bucket: AWS has a bug with accounts created as organizations which is blocking any abilty to have cloudfront.
# resource "aws_cloudfront_distribution" "site_distribution" {
#     origin {
#         domain_name = aws_s3_bucket.site.bucket_regional_domain_name
#         origin_id   = "S3-${aws_s3_bucket.site.bucket}"

#         s3_origin_config {
#         origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
#         }
#     }

#     enabled             = true
#     is_ipv6_enabled     = true
#     comment             = "CloudFront distribution for ${var.site_domain}"
#     default_root_object = "index.html"

#     default_cache_behavior {
#         target_origin_id       = "S3-${aws_s3_bucket.site.bucket}"
#         viewer_protocol_policy = "redirect-to-https"
#         allowed_methods        = ["GET", "HEAD", "OPTIONS"]
#         cached_methods         = ["GET", "HEAD"]

#         forwarded_values {
#         query_string = false
#         cookies {
#             forward = "none"
#         }
#         }

#         min_ttl                = 0
#         default_ttl            = 86400
#         max_ttl                = 31536000
#     }

#     price_class = "PriceClass_100"

#     restrictions {
#         geo_restriction {
#         restriction_type = "none"
#         }
#     }

#     viewer_certificate {
#         cloudfront_default_certificate = true
#     }
# }

# resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
#     comment = "OAI for ${aws_s3_bucket.site.bucket}"
# }


//State storage
terraform {
  backend "s3" {
    bucket  = "upstate-tech-pipelines-global-terraform-state"
    key     = "global_state/terraform.tfstate"
    region  = "us-east-1"
  }
}
