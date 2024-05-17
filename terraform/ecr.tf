resource "aws_ecr_repository" "nce_pipelines_repo" {
    name = var.ecr_repo_name
}