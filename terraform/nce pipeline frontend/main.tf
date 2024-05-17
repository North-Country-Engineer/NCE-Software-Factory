resource "aws_s3_bucket" "website_bucket" {
    bucket = "nce_pipelines_website_bucket"
    acl    = "public-read"

    website {
        index_document = "index.html"
        error_document = "error.html"
    }

    tags = {
        Name = "nce_pipelines_website_bucket"
    }
}

resource "aws_s3_bucket_policy" "website_bucket_policy" {
    bucket = aws_s3_bucket.website_bucket.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
        {
            Sid       = "PublicReadGetObject"
            Effect    = "Allow"
            Principal = "*"
            Action    = "s3:GetObject"
            Resource  = "${aws_s3_bucket.website_bucket.arn}/*"
        }
        ]
    })
}

resource "aws_cloudfront_distribution" "website_distribution" {
    origin {
        domain_name = aws_s3_bucket.website_bucket.bucket_regional_domain_name
        origin_id   = "WebsiteOrigin"
    }

    enabled             = true
    is_ipv6_enabled     = true
    default_root_object = "index.html"

    default_cache_behavior {
        allowed_methods  = ["GET", "HEAD"]
        cached_methods   = ["GET", "HEAD"]
        target_origin_id = "WebsiteOrigin"

        forwarded_values {
        query_string = false
        cookies {
            forward = "none"
        }
        }

        viewer_protocol_policy = "redirect-to-https"
        min_ttl                = 0
        default_ttl            = 3600
        max_ttl                = 86400
    }

    restrictions {
        geo_restriction {
        restriction_type = "none"
        }
    }

    viewer_certificate {
        cloudfront_default_certificate = true
    }

    tags = {
        Name = "nce_pipelines_website_distribution"
    }
}

output "website_endpoint" {
    value = aws_cloudfront_distribution.website_distribution.domain_name
}