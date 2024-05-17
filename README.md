# NCE Pipelines Infrastructure

This repository contains the Terraform code to provision the infrastructure for NCE Pipelines on AWS.

## Prerequisites

- Terraform (version X.X.X)
- AWS CLI (configured with appropriate credentials)

## Usage

1. Clone the repository:
2. Navigate to the repository directory:
3. Initialize the Terraform working directory:
4. Review and modify the variables in `variables.tf` as needed.
5. Preview the changes <terraform plan>
6. Apply the changes <terraform apply>
7. Confirm the changes by typing `yes` when prompted.

## Resources

The following resources will be provisioned:

- S3 bucket for storing artifacts
- ECR repository for storing Docker images
- ECS cluster
- ECS task definition
- ECS service
- VPC
- Subnets
- Security group
- Network ACL

## Configuration

The `variables.tf` file contains the configurable variables for the infrastructure. Modify the default values as needed.

## Cleanup

To destroy the provisioned resources, run:<terraform destroy>