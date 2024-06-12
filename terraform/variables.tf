variable "aws_region" {
    description = "The AWS region to deploy resources"
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
    default     = "UserPool_${site_domain}"
}

variable "user_pool_domain" {
    description = "Cognito user pool domain"
    default     = "UserPoolDomain_${site_domain}"
}

variable "user_pool_client" {
    description = "Cognito user pool client"
    default     = "UserPoolClient_${site_domain}"
}