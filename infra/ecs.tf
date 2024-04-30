resource "aws_ecs_cluster" "eval_sleuth" {
  name = "eval_sleuth"
}

resource "aws_ecs_task_definition" "eval_sleuth" {
  family                   = "eval_sleuth"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = file("./container_definitions.json")
}

resource "aws_ecs_service" "eval_sleuth" {
  name                              = "eval_sleuth"
  cluster                           = aws_ecs_cluster.eval_sleuth.arn
  task_definition                   = aws_ecs_task_definition.eval_sleuth.arn
  desired_count                     = 2
  launch_type                       = "FARGATE"
  platform_version                  = "1.3.0"
  health_check_grace_period_seconds = 60

  network_configuration {
    assign_public_ip = false
    security_groups  = [module.nginx_sg.security_group_id]

    subnets = [
      aws_subnet.private_0.id,
      aws_subnet.private_1.id,
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.eval_sleuth.arn
    container_name   = "eval_sleuth"
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}

module "nginx_sg" {
  source      = "./module/security_group"
  name        = "nginx-sg"
  vpc_id      = aws_vpc.eval_sleuth.id
  port        = 80
  cidr_blocks = [aws_vpc.eval_sleuth.cidr_block]
}
