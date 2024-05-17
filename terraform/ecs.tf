resource "aws_ecs_cluster" "nce_pipelines_cluster" {
    name = var.ecs_cluster_name
}

resource "aws_ecs_task_definition" "nce_pipelines_task" {
    family = var.ecs_task_family
    container_definitions = jsonencode([
        {
        name      = var.ecs_container_name
        image     = "${aws_ecr_repository.nce_pipelines_repo.repository_url}:latest"
        cpu       = var.ecs_task_cpu
        memory    = var.ecs_task_memory
        essential = true
        portMappings = [
            {
            containerPort = var.ecs_container_port
            hostPort      = var.ecs_host_port
            }
        ]
        }
    ])
    requires_compatibilities = ["FARGATE"]
    network_mode             = "awsvpc"
    memory                   = var.ecs_task_memory
    cpu                      = var.ecs_task_cpu
    execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
}

resource "aws_ecs_service" "nce_pipelines_service" {
    name            = var.ecs_service_name
    cluster         = aws_ecs_cluster.nce_pipelines_cluster.id
    task_definition = aws_ecs_task_definition.nce_pipelines_task.arn
    desired_count   = var.ecs_service_desired_count
    launch_type     = "FARGATE"
    network_configuration {
        subnets          = [aws_subnet.nce_pipelines_subnet_1.id, aws_subnet.nce_pipelines_subnet_2.id]
        security_groups  = [aws_security_group.nce_pipelines_security_group.id]
        assign_public_ip = true
  }
}