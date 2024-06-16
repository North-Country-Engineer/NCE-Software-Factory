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

data "archive_file" "authentication_lambda" {
    type = "zip"

    source_dir  = "${path.module}/lambda"
    output_path = "${path.module}/authentication_lambda.zip"
}

resource "aws_s3_object" "authentication_lambda" {
    bucket = aws_s3_bucket.lambda_bucket.id

    key    = "authentication_lambda.zip"
    source = data.archive_file.authentication_lambda.output_path

    etag = filemd5(data.archive_file.authentication_lambda.output_path)
}


resource "aws_cloudwatch_log_group" "auth_lambda_log_group" {
    name = "/aws/lambda/${aws_lambda_function.authentication_function.function_name}"

    retention_in_days = 30
}

resource "aws_iam_role" "lambda_exec" {
    name = "serverless_lambda"

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



resource "aws_lambda_function" "authentication_function" {
    function_name       = "auth_function"
    s3_bucket           = aws_s3_bucket.lambda_bucketa.id
    s3_key              = aws_s3_object.lambda_bucket.key
    runtime             = "nodejs20.x"
    handler             = "index.handler"
    source_code_hash    = data.archive_file.authentication_lambda.output_base64sha256
    role                = aws_iam_role.lambda_exec.arn

    environment {
        variables = {
            COGNITO_USER_POOL_ID     = aws_cognito_user_pool.main.id
            COGNITO_CLIENT_ID        = aws_cognito_user_pool_client.main.id
        }
    }
}


/*

resource "aws_api_gateway_rest_api" "auth_api" {
    name        = "auth_api"
    description = "API for user authentication"   
}

resource "aws_api_gateway_resource" "signup" {
    rest_api_id = aws_api_gateway_rest_api.auth_api.id
    parent_id   = aws_api_gateway_rest_api.auth_api.root_resource_id
    path_part   = "signup"
}

resource "aws_api_gateway_resource" "signin" {
    rest_api_id = aws_api_gateway_rest_api.auth_api.id
    parent_id   = aws_api_gateway_rest_api.auth_api.root_resource_id
    path_part   = "signin"
}

resource "aws_api_gateway_method" "signup_method" {
    rest_api_id   = aws_api_gateway_rest_api.auth_api.id
    resource_id   = aws_api_gateway_resource.signup.id
    http_method   = "POST"
    authorization = "NONE"
}

resource "aws_api_gateway_method" "signin_method" {
    rest_api_id   = aws_api_gateway_rest_api.auth_api.id
    resource_id   = aws_api_gateway_resource.signin.id
    http_method   = "POST"
    authorization = "NONE"
}

resource "aws_api_gateway_integration" "signup_integration" {
    rest_api_id             = aws_api_gateway_rest_api.auth_api.id
    resource_id             = aws_api_gateway_resource.signup.id
    http_method             = aws_api_gateway_method.signup_method.http_method
    integration_http_method = "POST"
    type                    = "AWS_PROXY"
    uri                     = aws_lambda_function.auth_function.invoke_arn
}

resource "aws_api_gateway_integration" "signin_integration" {
    rest_api_id             = aws_api_gateway_rest_api.auth_api.id
    resource_id             = aws_api_gateway_resource.signin.id
    http_method             = aws_api_gateway_method.signin_method.http_method
    integration_http_method = "POST"
    type                    = "AWS_PROXY"
    uri                     = aws_lambda_function.auth_function.invoke_arn
}

resource "aws_lambda_permission" "api_gateway" {
    statement_id  = "AllowAPIGatewayInvoke"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.auth_function.function_name
    principal     = "apigateway.amazonaws.com"
    source_arn    = "${aws_api_gateway_rest_api.auth_api.execution_arn}/* /*" REMOVE SPACE
}

resource "aws_api_gateway_deployment" "auth_api_deployment" {
    depends_on = [
        aws_api_gateway_integration.signup_integration,
        aws_api_gateway_integration.signin_integration
    ]
    rest_api_id = aws_api_gateway_rest_api.auth_api.id
    stage_name  = "prod"
}

*/
// Outputs 

output "cognito_user_pool_id" {
    value = aws_cognito_user_pool.main.id
}

output "cognito_user_pool_client_id" {
    value = aws_cognito_user_pool_client.main.id
}

output "cognito_user_pool_domain" {
    value = aws_cognito_user_pool_domain.main.domain
}

output "function_name" {
    description = "Name of the Lambda function."

    value = aws_lambda_function.authentication_function.function_name
}

# output "api_url" {
#     value = aws_api_gateway_deployment.auth_api_deployment.invoke_url
# }
