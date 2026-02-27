# ─── ALB Security Group ───────────────────────────────────────────────────────
# Ingress: HTTP (80) and HTTPS (443) from the public internet
# Egress:  ONLY to ECS task ports within the VPC — ALB never talks to the internet
#          This ensures backend port 8000 is unreachable directly from outside

resource "aws_security_group" "alb" {
  name_prefix = "${var.environment}-alb-sg-"
  description = "Allow HTTP/HTTPS inbound from internet; outbound only to ECS task ports within VPC"
  vpc_id      = var.vpc_id

  # ── Inbound: public internet ─────────────────────────────────────────────
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ── Outbound: restricted to ECS task ports inside the VPC only ───────────
  # The ALB only needs to forward HTTP to frontend (3000) and backend (8000).
  # Limiting egress to the VPC CIDR ensures the ALB cannot reach the internet,
  # making the backend (port 8000) unreachable from outside — it is only
  # accessible through the ALB's /api/* path rule.
  egress {
    description = "Forward to frontend tasks (port ${var.frontend_port}) inside VPC"
    from_port   = var.frontend_port
    to_port     = var.frontend_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Forward to backend tasks (port ${var.backend_port}) inside VPC only - not public"
    from_port   = var.backend_port
    to_port     = var.backend_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name        = "${var.environment}-alb-sg"
    Environment = var.environment
    Project     = var.project_name
  }

  # Must create new SG before destroying old — ALB holds a reference to it
  # and AWS blocks deletion of any SG attached to a load balancer.
  lifecycle {
    create_before_destroy = true
  }
}

# ─── Application Load Balancer ────────────────────────────────────────────────

resource "aws_lb" "main" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids # ALB lives in public subnets

  enable_deletion_protection = var.enable_deletion_protection

  tags = {
    Name        = "${var.environment}-alb"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ─── Target Group — Frontend (port 3000) ─────────────────────────────────────

resource "aws_lb_target_group" "frontend" {
  name        = "${var.environment}-frontend-tg"
  port        = var.frontend_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip" # required for Fargate awsvpc networking

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "${var.environment}-frontend-tg"
    Environment = var.environment
  }
}

# ─── Target Group — Backend (port 8000) ──────────────────────────────────────

resource "aws_lb_target_group" "backend" {
  name        = "${var.environment}-backend-tg"
  port        = var.backend_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/api/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "${var.environment}-backend-tg"
    Environment = var.environment
  }
}

# ─── HTTP Listener (port 80) ─────────────────────────────────────────────────
# Routes:
#   /api/*  → backend target group
#   /*      → frontend target group (default)

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  # Default → frontend
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

# ─── Listener Rule — /api/* → Backend ────────────────────────────────────────

resource "aws_lb_listener_rule" "backend_api" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}
