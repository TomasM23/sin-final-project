data "aws_region" "current" {}
data "aws_availability_zones" "available" { state = "available" }
data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

locals {
  prefix               = "${var.project_name}-${var.environment}"
  azs                  = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnet_cidrs  = [cidrsubnet(var.vpc_cidr, 8, 1), cidrsubnet(var.vpc_cidr, 8, 2)]
  private_subnet_cidrs = [cidrsubnet(var.vpc_cidr, 8, 10), cidrsubnet(var.vpc_cidr, 8, 20)]
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${local.prefix}-vpc", Environment = var.environment }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${local.prefix}-igw" }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.public_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true
  tags                    = { Name = "${local.prefix}-public-${count.index + 1}", Tier = "public" }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  cidr_block        = local.private_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]
  tags              = { Name = "${local.prefix}-private-${count.index + 1}", Tier = "private" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = { Name = "${local.prefix}-public-rt" }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "alb" {
  name        = "${local.prefix}-alb-sg"
  description = "Public HTTP ingress for the regional ALB"
  vpc_id      = aws_vpc.this.id

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

resource "aws_security_group" "app" {
  name        = "${local.prefix}-app-sg"
  description = "Application traffic from ALB and restricted SSH"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port       = 8080
    to_port         = 8081
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  dynamic "ingress" {
    for_each = var.admin_cidr == "" ? [] : [1]
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.admin_cidr]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "database" {
  name        = "${local.prefix}-db-sg"
  description = "PostgreSQL only from app instances"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_sqs_queue" "dlq" {
  name                      = "${local.prefix}-orders-dlq"
  message_retention_seconds = 1209600
}

resource "aws_sqs_queue" "orders" {
  name                       = "${local.prefix}-orders"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 345600
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_iam_role" "ec2" {
  name = "${local.prefix}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ec2" {
  name = "${local.prefix}-runtime"
  role = aws_iam_role.ec2.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["sqs:SendMessage", "sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:GetQueueUrl"]
        Resource = [aws_sqs_queue.orders.arn, aws_sqs_queue.dlq.arn]
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
        Resource = "arn:aws:secretsmanager:${data.aws_region.current.name}:*:secret:${var.db_secret_name}*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${local.prefix}-ec2-profile"
  role = aws_iam_role.ec2.name
}

resource "aws_instance" "app" {
  ami                         = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  key_name                    = var.key_name != "" ? var.key_name : null

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    region             = data.aws_region.current.name
    environment        = var.environment
    queue_url          = aws_sqs_queue.orders.url
    db_secret_name     = var.db_secret_name
    dockerhub_username = var.dockerhub_username
    image_tag          = var.image_tag
  })

  user_data_replace_on_change = true
  tags                        = { Name = "${local.prefix}-app", Environment = var.environment }
}

resource "aws_lb" "app" {
  name               = substr("${local.prefix}-alb", 0, 32)
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
}

resource "aws_lb_target_group" "catalog" {
  name     = substr("${local.prefix}-catalog", 0, 32)
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.this.id

  health_check {
    enabled             = true
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 15
    timeout             = 5
    matcher             = "200"
  }
}

resource "aws_lb_target_group" "orders" {
  name     = substr("${local.prefix}-orders", 0, 32)
  port     = 8081
  protocol = "HTTP"
  vpc_id   = aws_vpc.this.id

  health_check {
    enabled             = true
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 15
    timeout             = 5
    matcher             = "200"
  }
}

resource "aws_lb_target_group_attachment" "catalog" {
  target_group_arn = aws_lb_target_group.catalog.arn
  target_id        = aws_instance.app.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "orders" {
  target_group_arn = aws_lb_target_group.orders.arn
  target_id        = aws_instance.app.id
  port             = 8081
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.catalog.arn
  }
}

resource "aws_lb_listener_rule" "orders" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.orders.arn
  }

  condition {
    path_pattern { values = ["/orders", "/orders/*"] }
  }
}
