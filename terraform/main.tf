
terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 4.0"
        }
    }
}

provider "aws" {
    region = var.aws_region
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
}

# IAM - Commented out other than for initial stage builds

/*
# Check for existing IAM Role
data "aws_iam_role" "existing_github_actions_role" {
    name = "github-actions-role"
}

# Check for existing IAM Policy
data "aws_iam_policy" "existing_github_actions_policy" {
    arn = var.actions_role_arn
}

# IAM Role - Create only if the role does not already exist
resource "aws_iam_role" "github_actions_role" {
    count = length(data.aws_iam_role.existing_github_actions_role.name) == 0 ? 1 : 0

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

# IAM Policy - Create only if the policy does not already exist
resource "aws_iam_policy" "github_actions_policy" {
    count = length(data.aws_iam_policy.existing_github_actions_policy.arn) == 0 ? 1 : 0

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
    count = length(data.aws_iam_role.existing_github_actions_role.name) == 0 ? 1 : 0

    role       = aws_iam_role.github_actions_role.name
    policy_arn = aws_iam_policy.github_actions_policy.arn
}

# Output the Role ARN
output "github_actions_role_arn" {
    value = coalesce(data.aws_iam_role.existing_github_actions_role.arn, aws_iam_role.github_actions_role.arn)
}
*/

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
                    AWS: "${{var.actions_role_arn}}"
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
