variable "aws_region" {
    description = "The AWS region to deploy resources"
    default     = "us-east-1"
}

// Cloudflare Environment Variable definitions
variable "site_domain" {
    type    = string
    default = "www.upstate-tech.dev"
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