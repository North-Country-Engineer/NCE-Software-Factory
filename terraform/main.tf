
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

//CLOUDFLARE SETUP REQUIRED FOR FIRST DEPLOYMENT TO NEW ENVIRONMENT, COMMENTED
//DUE TO LIMITATION WITH TERRAFORM AS IT WILL FAIL IF A RECORD ALREADY EXISTS

/* 
provider "cloudflare" {
    api_token = var.cloudflare_api_token
}

resource "cloudflare_record" "website" {
    zone_id = ${{var.zone_id}}
    name    = ${{var.site_id}}
    type    = "CNAME"
    value   = "http://${{var.site_id}}.s3-website-us-east-1.amazonaws.com/"
    proxied = true
    ttl     = 3600
}

*/