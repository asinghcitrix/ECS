provider "aws" {
  region = "us-east-2"  # Replace with your AWS region
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"  # Replace with your VPC CIDR block
}

resource "aws_subnet" "example" {
  count             = 2
  vpc_id            = aws_vpc.example.id
  cidr_block        = cidrsubnet(aws_vpc.example.cidr_block, 8, count.index)
  availability_zone = "us-east-2a"  # Replace with your preferred availability zone
}

resource "aws_security_group" "example" {
  name        = "example-security-group"
  description = "Allow traffic to ECS service"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Adjust as per your security requirements
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb" "example" {
  name               = "example-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["sg-0dc8d4bcbbaf828dc"]
  subnets            = "subnet-06370e92c0c296da1"
}

resource "aws_alb_target_group" "example" {
  name     = "example-target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = "vpc-0a3cf9887fe999c01"

  health_check {
    path                = "/healthcheck"  # Adjust health check path as needed
    interval            = 30
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

resource "aws_alb_listener" "example" {
  load_balancer_arn = aws_alb.example.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.example.arn
  }
}
