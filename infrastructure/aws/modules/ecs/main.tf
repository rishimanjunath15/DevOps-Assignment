# ─── ECS Cluster ─────────────────────────────────────────────────────────────

resource "aws_ecs_cluster" "main" {
  name = "${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = {
    Name        = "${var.environment}-cluster"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = var.use_spot ? "FARGATE_SPOT" : "FARGATE"
    weight            = 1
    base              = 1
  }
}

# ─── CloudWatch Log Groups ────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.environment}/backend"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
    Service     = "backend"
  }
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${var.environment}/frontend"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
    Service     = "frontend"
  }
}

# ─── IAM — Task Execution Role (ECS agent pulls images, writes logs) ─────────

resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.environment}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ─── IAM — Task Role (the app itself — add S3/Secrets/etc. here later) ────────

resource "aws_iam_role" "ecs_task" {
  name = "${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Environment = var.environment
  }
}

# ─── Security Group — ECS Tasks ───────────────────────────────────────────────
# Ingress: ONLY from the ALB security group on the exact container ports.
#          No rule allows traffic from 0.0.0.0/0 — backend (8000) and
#          frontend (3000) are completely unreachable from the internet.
# Egress:  dev/staging = open (ECR pull, no NAT)
#          prod        = HTTPS (443) + DNS (53) only

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.environment}-ecs-tasks-sg"
  description = "Allow inbound from ALB only; all outbound"
  vpc_id      = var.vpc_id

  # Allow traffic from the ALB security group on backend port
  ingress {
    description     = "Backend port from ALB"
    from_port       = var.backend_port
    to_port         = var.backend_port
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  # Allow traffic from the ALB security group on frontend port
  ingress {
    description     = "Frontend port from ALB"
    from_port       = var.frontend_port
    to_port         = var.frontend_port
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  # dev/staging: unrestricted outbound (pull images, call AWS APIs)
  dynamic "egress" {
    for_each = var.restrict_outbound_egress ? [] : [1]
    content {
      description = "All outbound (dev/staging)"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # prod: HTTPS only — ECR pull, CloudWatch Logs, AWS APIs all use 443
  dynamic "egress" {
    for_each = var.restrict_outbound_egress ? [443] : []
    content {
      description = "HTTPS outbound for ECR, CloudWatch, AWS APIs"
      from_port   = egress.value
      to_port     = egress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # prod: DNS resolution (required for ECR endpoint lookups)
  dynamic "egress" {
    for_each = var.restrict_outbound_egress ? [53] : []
    content {
      description = "DNS resolution"
      from_port   = egress.value
      to_port     = egress.value
      protocol    = "udp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = {
    Name        = "${var.environment}-ecs-tasks-sg"
    Environment = var.environment
  }
}

# ─── Task Definition — Backend ────────────────────────────────────────────────

resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.environment}-backend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.backend_cpu
  memory                   = var.backend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "${var.ecr_backend_url}:${var.image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = var.backend_port
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "ENVIRONMENT", value = var.environment },
        { name = "PORT",        value = tostring(var.backend_port) }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "backend"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "python -c \"import urllib.request; urllib.request.urlopen('http://localhost:${var.backend_port}/api/health')\" || exit 1"]
        interval    = 30
        timeout     = 10
        retries     = 3
        startPeriod = 15
      }
    }
  ])

  tags = {
    Environment = var.environment
    Service     = "backend"
  }
}

# ─── Task Definition — Frontend ───────────────────────────────────────────────

resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.environment}-frontend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.frontend_cpu
  memory                   = var.frontend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = "${var.ecr_frontend_url}:${var.image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = var.frontend_port
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "ENVIRONMENT",           value = var.environment },
        { name = "PORT",                  value = tostring(var.frontend_port) },
        { name = "NEXT_PUBLIC_API_URL",   value = var.backend_url }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.frontend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "frontend"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "wget -q --spider http://localhost:${var.frontend_port}/ || exit 1"]
        interval    = 30
        timeout     = 10
        retries     = 3
        startPeriod = 20
      }
    }
  ])

  tags = {
    Environment = var.environment
    Service     = "frontend"
  }
}

# ─── ECS Service — Backend ────────────────────────────────────────────────────

resource "aws_ecs_service" "backend" {
  name            = "${var.environment}-backend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = var.backend_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.task_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = var.assign_public_ip
  }

  load_balancer {
    target_group_arn = var.backend_target_group_arn
    container_name   = "backend"
    container_port   = var.backend_port
  }

  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_task_execution]

  tags = {
    Environment = var.environment
    Service     = "backend"
  }
}

# ─── ECS Service — Frontend ───────────────────────────────────────────────────

resource "aws_ecs_service" "frontend" {
  name            = "${var.environment}-frontend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = var.frontend_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.task_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = var.assign_public_ip
  }

  load_balancer {
    target_group_arn = var.frontend_target_group_arn
    container_name   = "frontend"
    container_port   = var.frontend_port
  }

  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_task_execution]

  tags = {
    Environment = var.environment
    Service     = "frontend"
  }
}

# ─── Auto Scaling — Backend ───────────────────────────────────────────────────
# Disabled in dev (single task, no need to scale)
# Enabled in staging/prod via enable_autoscaling = true

resource "aws_appautoscaling_target" "backend" {
  count              = var.enable_autoscaling ? 1 : 0
  max_capacity       = var.backend_max_capacity
  min_capacity       = var.backend_min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.backend.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "backend_cpu" {
  count              = var.enable_autoscaling ? 1 : 0
  name               = "${var.environment}-backend-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.backend[0].resource_id
  scalable_dimension = aws_appautoscaling_target.backend[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.backend[0].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = var.autoscaling_cpu_target   # staging=70, prod=60
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
    # prod sets autoscaling_scale_in_threshold=30, which means we manage scale-in
    # explicitly via a step scaling alarm below. Disable target tracking's own
    # scale-in to prevent the two policies fighting.
    disable_scale_in   = var.autoscaling_scale_in_threshold > 0

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

resource "aws_appautoscaling_policy" "backend_memory" {
  count              = var.enable_autoscaling ? 1 : 0
  name               = "${var.environment}-backend-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.backend[0].resource_id
  scalable_dimension = aws_appautoscaling_target.backend[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.backend[0].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = var.autoscaling_memory_target
    scale_in_cooldown  = 300
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
  }
}

# ─── Auto Scaling — Frontend ──────────────────────────────────────────────────

resource "aws_appautoscaling_target" "frontend" {
  count              = var.enable_autoscaling ? 1 : 0
  max_capacity       = var.frontend_max_capacity
  min_capacity       = var.frontend_min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.frontend.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "frontend_cpu" {
  count              = var.enable_autoscaling ? 1 : 0
  name               = "${var.environment}-frontend-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.frontend[0].resource_id
  scalable_dimension = aws_appautoscaling_target.frontend[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.frontend[0].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = var.autoscaling_cpu_target   # staging=70, prod=60
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
    disable_scale_in   = var.autoscaling_scale_in_threshold > 0

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

resource "aws_appautoscaling_policy" "frontend_memory" {
  count              = var.enable_autoscaling ? 1 : 0
  name               = "${var.environment}-frontend-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.frontend[0].resource_id
  scalable_dimension = aws_appautoscaling_target.frontend[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.frontend[0].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = var.autoscaling_memory_target
    scale_in_cooldown  = 300
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
  }
}

# ─── Explicit Scale-In (prod only: CPU < autoscaling_scale_in_threshold for 15min) ────
# Staging uses target tracking's built-in scale-in (symmetric around target).
# Prod disables target tracking's scale-in (disable_scale_in=true above) and
# instead uses a CloudWatch alarm + step scaling policy:
#   • Scale OUT at CPU > 60%  (target tracking, 60s cooldown)
#   • Scale IN  at CPU < 30%  (step scaling alarm, 15 consecutive minutes)
# This prevents premature scale-in from brief CPU drops during request bursts.

resource "aws_appautoscaling_policy" "backend_scale_in_step" {
  count              = var.enable_autoscaling && var.autoscaling_scale_in_threshold > 0 ? 1 : 0
  name               = "${var.environment}-backend-scale-in-step"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.backend[0].resource_id
  scalable_dimension = aws_appautoscaling_target.backend[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.backend[0].service_namespace

  step_scaling_policy_configuration {
    adjustment_type          = "ChangeInCapacity"
    cooldown                 = 300
    metric_aggregation_type  = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0   # fires when metric is AT or BELOW threshold
      scaling_adjustment          = -1  # remove 1 task
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "backend_scale_in_cpu" {
  count               = var.enable_autoscaling && var.autoscaling_scale_in_threshold > 0 ? 1 : 0
  alarm_name          = "${var.environment}-backend-cpu-low"
  alarm_description   = "Scale in backend: CPU below ${var.autoscaling_scale_in_threshold}% for 15 consecutive minutes"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 15
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.autoscaling_scale_in_threshold

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.backend.name
  }

  alarm_actions = [aws_appautoscaling_policy.backend_scale_in_step[0].arn]

  tags = {
    Environment = var.environment
    Service     = "backend"
  }
}

resource "aws_appautoscaling_policy" "frontend_scale_in_step" {
  count              = var.enable_autoscaling && var.autoscaling_scale_in_threshold > 0 ? 1 : 0
  name               = "${var.environment}-frontend-scale-in-step"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.frontend[0].resource_id
  scalable_dimension = aws_appautoscaling_target.frontend[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.frontend[0].service_namespace

  step_scaling_policy_configuration {
    adjustment_type          = "ChangeInCapacity"
    cooldown                 = 300
    metric_aggregation_type  = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "frontend_scale_in_cpu" {
  count               = var.enable_autoscaling && var.autoscaling_scale_in_threshold > 0 ? 1 : 0
  alarm_name          = "${var.environment}-frontend-cpu-low"
  alarm_description   = "Scale in frontend: CPU below ${var.autoscaling_scale_in_threshold}% for 15 consecutive minutes"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 15
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.autoscaling_scale_in_threshold

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.frontend.name
  }

  alarm_actions = [aws_appautoscaling_policy.frontend_scale_in_step[0].arn]

  tags = {
    Environment = var.environment
    Service     = "frontend"
  }
}
