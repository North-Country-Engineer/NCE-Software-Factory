output "website_bucket_name" {
    description = "Name (id) of the bucket"
    value       = aws_s3_bucket.site.id
}

output "bucket_endpoint" {
    description = "Bucket endpoint"
    value       = aws_s3_bucket_website_configuration.site.website_endpoint
}

output "domain_name" {
    description = "Website endpoint"
    value       = var.site_domain
}

output "api_gateway_endpoint" {
    description = "API gateway endpoint"
    value       = aws_apigatewayv2_api.api.api_endpoint
}

output "github_actions_role_arn" {
    value = aws_iam_role.github_actions_role.arn
}

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