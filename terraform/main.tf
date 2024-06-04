
terraform {
    required_providers {
        cloudflare = {
            source = "cloudflare/cloudflare"
            version = "~> 4"
        }
        aws = {
            source  = "hashicorp/aws"
            version = "~> 4.0"
        }
    }
}

provider "aws" {
    region  = var.aws_region
    profile = "sandbox"
}

//CLOUDFLARE
provider "cloudflare" {
    api_token = var.cloudflare_api_token
}

resource "cloudflare_record" "www" {
    zone_id = var.zone_id
    name    = "www"
    value   = "203.0.113.10"
    type    = "A"
    proxied = true
}

//AWS S3
resource "aws_s3_bucket" "site" {
    bucket = var.site_domain
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
        key = "error.html"
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
        Version = "2012-10-17"
        Statement = [
        {
            Sid       = "PublicReadGetObject"
            Effect    = "Allow"
            Principal = "*"
            Action    = "s3:GetObject"
            Resource = [
            aws_s3_bucket.site.arn,
            "${aws_s3_bucket.site.arn}/*",
            ]
        },
        ]
    })

    depends_on = [
        aws_s3_bucket_public_access_block.site
    ]
}