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

/*
variable "cloudflare_api_token" {
    type    = string
}

variable "cloudflare_email" {
    type    = string 
}

variable "zone_id" {
    type    = string
}

variable "account_id" {
    type    = string
}
*/
