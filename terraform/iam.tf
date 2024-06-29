# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions_role" {
    name = "github-actions-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
        {
            Effect = "Allow",
            Principal = {
                AWS = "arn:aws:iam::${var.AWS_ACCOUNT_ID}:user/Admin_User"
            },
            Action = ["sts:AssumeRole", "sts:TagSession"]
        }
        ]
    })
}

resource "aws_iam_policy" "github_actions_sts_policy" {
    name        = "github-actions-sts-policy"
    description = "Policy for GitHub Actions to assume a role"
    policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
        {
            Effect   = "Allow",
            Action   = ["sts:AssumeRole", "sts:TagSession"],
            Resource = aws_iam_role.github_actions_role.arn
        }
        ]
    })
}

# IAM Policy to allow GitHub Actions to access the S3 bucket
resource "aws_iam_policy" "github_actions_s3_policy" {
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

# IAM Policy to allow GitHub Actions to access the S3 bucket
resource "aws_iam_policy" "github_actions_lambda_invoke_policy" {
    name        = "github-actions-policy"
    description = "Policy for GitHub Actions to access S3 bucket"
    policy      = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": "lambda:InvokeFunction",
                "Resource": ${module.lambda.lambda_function_arn}
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "github_actions_sts_policy_attachment" {
    role       = aws_iam_role.github_actions_role.name
    policy_arn = aws_iam_policy.github_actions_sts_policy.arn
}

resource "aws_iam_role_policy_attachment" "github_actions_S3_policy_attachment" {
    role       = aws_iam_role.github_actions_role.name
    policy_arn = aws_iam_policy.github_actions_s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "github_actions_lambda_invoke_attachment" {
    role       = aws_iam_role.github_actions_role.name
    policy_arn = aws_iam_policy.github_actions_lambda_invoke_policy.arn
}

resource "aws_iam_role_policy_attachment" "github_actions_lambda_invoke_policy_attachment" {
    role       = aws_iam_role.github_actions_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonCognitoPowerUser" #todo: not this
}

resource "aws_iam_role_policy_attachment" "github_actions_iam_access" {
    role       = aws_iam_role.github_actions_role.name
    policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess" #todo: not this
}
