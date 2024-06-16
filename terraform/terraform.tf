terraform {  
    required_version = "~> 1.6"
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 5.38.0"
        }
        cloudflare = {
            source  = "cloudflare/cloudflare"
            version = ">= 4.20"
        }
        archive = {
            source  = "hashicorp/archive"
            version = "~> 2.4.2"
        }
    }
}