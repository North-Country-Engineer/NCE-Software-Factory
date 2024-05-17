resource "aws_s3_bucket" "nce_pipelines_artifact_store" {
    bucket = var.s3_bucket_name
    acl    = "private"
}