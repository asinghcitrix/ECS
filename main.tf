provider "aws" {
  region = "us-east-2"
}

# Include variables
variable "aws_region" {
  description = "The AWS region to deploy to"
  default     = "us-east-2"
}

variable "ecr_repository_url" {
  description = "The URL of the ECR repository"
  default     = "637423421797.dkr.ecr.us-east-2.amazonaws.com/devops-fortune-api"
}

variable "cluster_name" {
  description = "The name of the ECS cluster"
  default     = "devops-fortune-cluster"
}

variable "service_name" {
  description = "The name of the ECS service"
  default     = "devops-fortune-service"
}

variable "task_family" {
  description = "The family name of the ECS task definition"
  default     = "devops-fortune-task"
}

# IAM roles and policies
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "ecs_task_execution_role_policy" {
  name       = "ecsTaskExecutionRolePolicyAttachment"
  roles      = [aws_iam_role.ecs_task_execution_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Cluster
resource "aws_ecs_cluster" "cluster" {
  name = var.cluster_name
}

# ECS Task Definition
resource "aws_ecs_task_definition" "task" {
  family                   = var.task_family
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "devops-fortune-container"
      image     = var.ecr_repository_url
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "service" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = ["subnet-0cc71f36f26b6b03a", "subnet-01da053285ed1019b"]
    security_groups  = ["sg-089c907eb24429082"]
    assign_public_ip = true
  }
}

# Networking (VPC, Subnets, Security Groups)
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_subnet" "subnet-2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
}

resource "aws_security_group" "sg" {
  name        = "allow-web-traffic"
  description = "Allow inbound HTTP traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Outputs
output "ecs_cluster_id" {
  value = aws_ecs_cluster.cluster.id
}

output "ecs_service_name" {
  value = aws_ecs_service.service.name
}

output "ecs_task_definition_arn" {
  value = aws_ecs_task_definition.task.arn
}
