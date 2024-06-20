// User pool and client for authentication
resource "aws_cognito_user_pool" "main" {
    name = "upstate_tech_user_pool"

    password_policy {
        minimum_length    = 8
        require_lowercase = true
        require_uppercase = true
        require_numbers   = true
        require_symbols   = false
    }

    auto_verified_attributes = ["email"]

    tags = {
        Name = "update-tech-user-pool"
    }
}

resource "aws_cognito_user_pool_domain" "main" {
    domain      = "upstate-tech-auth"
    user_pool_id = aws_cognito_user_pool.main.id
}

resource "aws_cognito_user_pool_client" "main" {
    name         = "update-tech-user-pool-client"
    user_pool_id = aws_cognito_user_pool.main.id
    generate_secret = false

    explicit_auth_flows = [
        "ALLOW_USER_PASSWORD_AUTH",
        "ALLOW_REFRESH_TOKEN_AUTH",
        "ALLOW_USER_SRP_AUTH",
        "ALLOW_CUSTOM_AUTH",
    ]

    allowed_oauth_flows_user_pool_client = true

    allowed_oauth_flows = [
        "code",
        "implicit"
    ]

    allowed_oauth_scopes = [
        "phone",
        "email",
        "openid",
        "profile",
        "aws.cognito.signin.user.admin"
    ]

    callback_urls = [
        "https://${var.site_domain}/callback"
    ]

    logout_urls = [
        "https://${var.site_domain}/logout"
    ]
}



// Lambda function to handle authentication
resource "aws_s3_bucket" "lambda_bucket" {
    bucket = "authentication-lambda-store-${var.site_domain}"
}

resource "aws_s3_bucket_ownership_controls" "lambda_bucket" {
    bucket = aws_s3_bucket.lambda_bucket.id
    rule {
        object_ownership = "BucketOwnerPreferred"
    }
}

resource "aws_s3_bucket_acl" "lambda_bucket" {
    depends_on = [aws_s3_bucket_ownership_controls.lambda_bucket]

    bucket = aws_s3_bucket.lambda_bucket.id
    acl    = "private"
}

resource "null_resource" "build_lambda" {
    provisioner "local-exec" {
        command = "cd ${path.module}/lambda && npm install"
    }
}

data "archive_file" "authentication_lambda" {
    type = "zip"

    source_dir  = "${path.module}/lambda"
    output_path = "${path.module}/authentication_lambda.zip"
}

resource "aws_s3_object" "authentication_lambda-object" {
    bucket = aws_s3_bucket.lambda_bucket.id

    key    = "authentication_lambda.zip"
    source = data.archive_file.authentication_lambda.output_path

    etag = filemd5(data.archive_file.authentication_lambda.output_path)
}


# resource "aws_cloudwatch_log_group" "auth_lambda_log_group" {
#     name = "/aws/lambda/${aws_lambda_function.authentication_function.function_name}"

#     retention_in_days = 30
# }

resource "aws_iam_role" "lambda_exec" {
    name = "upstate_tech_lambda_execution_role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                    Effect = "Allow"
                    Sid    = ""
                    Principal = {
                        Service = "lambda.amazonaws.com"
                    }
            }
        ]
    })

    inline_policy {
        name = "lambda-policy"
        policy = jsonencode({
            Version = "2012-10-17",
            Statement = [
                {
                    Action = [
                        "logs:CreateLogGroup",
                        "logs:CreateLogStream",
                        "logs:PutLogEvents"
                    ],
                    Effect   = "Allow",
                    Resource = "*"
                },
                {
                    Action = [
                        "cognito-idp:SignUp",
                        "cognito-idp:InitiateAuth",
                        "cognito-idp:AdminInitiateAuth"
                    ],
                    Effect   = "Allow",
                    Resource = "*"
                }
            ]
        })
    }
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
    role       = aws_iam_role.lambda_exec.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}



# resource "aws_lambda_function" "authentication_function" {
#     function_name       = "auth_function"
#     s3_bucket           = aws_s3_bucket.lambda_bucket.id
#     s3_key              = aws_s3_object.authentication_lambda-object.key
#     runtime             = "nodejs20.x"
#     handler             = "index.handler"
#     source_code_hash    = data.archive_file.authentication_lambda.output_base64sha256
#     role                = aws_iam_role.lambda_exec.arn

#     environment {
#         variables = {
#             COGNITO_USER_POOL_ID     = aws_cognito_user_pool.main.id
#             COGNITO_CLIENT_ID        = aws_cognito_user_pool_client.main.id
#         }
#     }
# }


# Use the terraform-aws-lambda module to deploy the Lambda function
module "lambda" {
    source = "terraform-aws-modules/lambda/aws"

    function_name = "auth_function"
    description   = "AWS Lambda function for user authentication using AWS Cognito"
    handler       = "index.handler"
    runtime       = "nodejs14.x"

    source_path   = "./lambda"

    environment_variables = {
        COGNITO_USER_POOL_ID = aws_cognito_user_pool.main.id
        COGNITO_CLIENT_ID    = aws_cognito_user_pool_client.main.id
    }

    layers = []

    tags = {
        Terraform = "true"
        Environment = "dev"
    }

    role_name = aws_iam_role.lambda_exec.name
}





// APIG

resource "aws_apigatewayv2_api" "lambda" {
    name          = "serverless_lambda_gw"
    protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda" {
    api_id = aws_apigatewayv2_api.lambda.id

    name        = "serverless_lambda_stage"
    auto_deploy = true

    access_log_settings {
        destination_arn = aws_cloudwatch_log_group.api_gw.arn

        format = jsonencode({
            requestId               = "$context.requestId"
            sourceIp                = "$context.identity.sourceIp"
            requestTime             = "$context.requestTime"
            protocol                = "$context.protocol"
            httpMethod              = "$context.httpMethod"
            resourcePath            = "$context.resourcePath"
            routeKey                = "$context.routeKey"
            status                  = "$context.status"
            responseLength          = "$context.responseLength"
            integrationErrorMessage = "$context.integrationErrorMessage"
        }
        )
    }
}

resource "aws_apigatewayv2_integration" "authentication" {
    api_id = aws_apigatewayv2_api.lambda.id
    integration_uri    = module.lambda.lambda_function_arn
    integration_type   = "AWS_PROXY"
    integration_method = "POST"
}

resource "aws_apigatewayv2_route" "base_path" {
    api_id = aws_apigatewayv2_api.lambda.id

    route_key = "GET /"
    target    = "integrations/${aws_apigatewayv2_integration.authentication.id}"
}

resource "aws_apigatewayv2_route" "sign_up" {
    api_id = aws_apigatewayv2_api.lambda.id

    route_key = "POST /signup"
    target    = "integrations/${aws_apigatewayv2_integration.authentication.id}"
}

resource "aws_apigatewayv2_route" "sign_in" {
    api_id = aws_apigatewayv2_api.lambda.id

    route_key = "POST /signin"
    target    = "integrations/${aws_apigatewayv2_integration.authentication.id}"
}



resource "aws_cloudwatch_log_group" "api_gw" {
    name = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"

    retention_in_days = 30
}

resource "aws_lambda_permission" "api_gw" {
    statement_id  = "AllowExecutionFromAPIGateway"
    action        = "lambda:InvokeFunction"
    function_name = module.lambda.lambda_function_name
    principal     = "apigateway.amazonaws.com"

    source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}




// Outputs 

output "cognito_user_pool_id" {
    description = "User Pool ID"
    value = aws_cognito_user_pool.main.id
}

output "cognito_user_pool_client_id" {
    description = "User Pool Client ID"
    value = aws_cognito_user_pool_client.main.id
}

output "cognito_user_pool_domain" {
    description = "Cognito User Pool Domain"
    value = aws_cognito_user_pool_domain.main.domain
}

output "base_url" {
    description = "Base URL for API Gateway stage."
    value = aws_apigatewayv2_stage.lambda.invoke_url
}






