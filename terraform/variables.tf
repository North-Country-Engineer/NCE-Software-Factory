variable "aws_region" {
    description = "The AWS region to deploy resources"
    default     = "us-east-1"
}

variable "aws_access_key" {
    description = "The AWS access key to use for deployment"
}

variable "aws_secret_key" {
    description = "The AWS secret key to use for deployment"
}

variable "site_domain" {
    description = "Target site domain; will be S3 bucket name as well as target domain"
}

variable "cloudflare_api_token" {
    description = "Cloudflare API token"
}

variable "cloudflare_zone_id" {
    description = "Cloudflare zone ID"
}

variable "cloudflare_email" {
    description = "Cloudflare email"
}

variable "user_pool_name" {
    description = "Cognito user pool name"
    default     = "update-tech-user-pool"
}

variable "user_pool_client" {
    description = "Cognito user pool client"
    default     = "update-tech-user-pool-client"
}

variable "allow_headers" {
    description = "Allow headers"
    type        = list(string)

    default = [
        "Authorization",
        "Content-Type",
        "X-Amz-Date",
        "X-Amz-Security-Token",
        "X-Api-Key",
    ]
}

variable "allow_methods" {
    description = "Allow methods"
    type        = list(string)

    default = [
        "OPTIONS",
        "HEAD",
        "GET",
        "POST",
        "PUT",
        "PATCH",
        "DELETE",
    ]
}

variable "allow_origins" {
    description = "Allow origin"
    type        = list(string)
    default     = ["*"]
}

variable "put_api_routes" {
    description = "List of API routes for authentication"
    type        = list(string)
    default     = [
        "signup", 
        "signin", 
        "validate", 
        "getUserAttributes"
    ]
}

variable "AWS_ACCOUNT_ID" {
    description = "AWS account ID"
}

