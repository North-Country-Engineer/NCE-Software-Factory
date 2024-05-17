variable "aws_region" {
    description = "The AWS region to deploy resources"
    default     = "us-east-1"
}

variable "s3_bucket_name" {
    description = "The name of the S3 bucket for storing artifacts"
    default     = "nce_pipelines_artifact_store"
}

variable "ecr_repo_name" {
    description = "The name of the ECR repository"
    default     = "nce_pipelines_ecr_repo"
}

variable "ecs_cluster_name" {
    description = "The name of the ECS cluster"
    default     = "nce_pipelines_ecs_cluster"
}

variable "ecs_task_family" {
    description = "The family name of the ECS task definition"
    default     = "nce_pipelines_task"
}

variable "ecs_container_name" {
    description = "The name of the container in the ECS task definition"
    default     = "nce_pipelines_container"
}

variable "ecs_task_cpu" {
    description = "The CPU units for the ECS task"
    default     = 256
}

variable "ecs_task_memory" {
    description = "The memory limit (in MiB) for the ECS task"
    default     = 512
}

variable "ecs_container_port" {
    description = "The port on which the container listens"
    default     = 8080
}

variable "ecs_host_port" {
    description = "The host port for the container"
    default     = 8080
}

variable "ecs_service_name" {
    description = "The name of the ECS service"
    default     = "nce_pipelines_ECS_nce_pipelines_service"
}

variable "ecs_service_desired_count" {
    description = "The desired number of tasks for the ECS service"
    default     = 1
}

variable "vpc_cidr_block" {
    description = "The CIDR block for the VPC"
    default     = "10.0.0.0/20"
}

variable "vpc_name" {
    description = "The name of the VPC"
    default     = "nce_pipelines_vpc"
}

variable "subnet_1_cidr_block" {
    description = "The CIDR block for subnet 1"
    default     = "10.0.1.0/24"
}

variable "subnet_1_name" {
    description = "The name of subnet 1"
    default     = "nce_pipelines_subnet-1"
}

variable "subnet_2_cidr_block" {
    description = "The CIDR block for subnet 2"
    default     = "10.0.2.0/24"
}

variable "subnet_2_name" {
    description = "The name of subnet 2"
    default     = "nce_pipelines_subnet-2"
}

variable "security_group_name_prefix" {
    description = "The prefix for the security group name"
    default     = "nce-pipelines-sg-"
}

variable "security_group_ingress_from_port" {
    description = "The start port for incoming traffic to the security group"
    default     = 8080
}

variable "security_group_ingress_to_port" {
    description = "The end port for incoming traffic to the security group"
    default     = 8080
}

variable "security_group_ingress_protocol" {
    description = "The protocol for incoming traffic to the security group"
    default     = "tcp"
}

variable "security_group_name" {
    description = "The name of the security group"
    default     = "nce_pipelines_security_group"
}

variable "network_acl_ingress_protocol" {
    description = "The protocol for incoming traffic to the network ACL"
    default     = "tcp"
}

variable "network_acl_ingress_from_port" {
    description = "The start port for incoming traffic to the network ACL"
    default     = 8080
}

variable "network_acl_ingress_to_port" {
    description = "The end port for incoming traffic to the network ACL"
    default     = 8080
}

variable "network_acl_name" {
    description = "The name of the network ACL"
    default     = "nce_pipelines_network-acl"
}