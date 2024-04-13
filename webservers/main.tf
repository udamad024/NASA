# Terraform Config file (main.tf). This has provider block (AWS) and config for provisioning one EC2 instance resource.  

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.27"
    }
  }

  required_version = ">=0.14"
}
provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

data "terraform_remote_state" "public_subnet" { // This is to use Outputs from Remote State
  backend = "s3"
  config = {
    bucket = "lab2tfstate"             // Bucket from where to GET Terraform State
    key    = "Non-prod/network/terraform.tfstate" // Object name in the bucket to GET Terraform State
    region = "us-east-1"                     // Region where bucket created
  }
}

# Data source for AMI id
data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Data source for availability zones in us-east-1
data "aws_availability_zones" "available" {
  state = "available"
}

# Define tags locally
locals {
  default_tags = merge(var.default_tags, { "env" = var.env })
  name_prefix  = "${var.prefix}-${var.env}"

}

#faseh instances 


# - end 


#jun instances


# - end




#Application LB

resource "aws_security_group" "alb_sg" {
  name        = "${var.prefix}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = data.terraform_remote_state.public_subnet.outputs.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Add additional ingress block here for HTTPS (port 443) if needed
  # ...

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.default_tags,
    { "Name" = "${var.prefix}-alb-sg" }
  )
}

resource "aws_lb" "main_alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = slice(data.terraform_remote_state.public_subnet.outputs.public_subnet_ids[*], 0, 3)  # Adjust the slice as needed to select the public subnets

  tags = merge(
    local.default_tags,
    { "Name" = "${var.prefix}-alb" }
  )
}


resource "aws_lb_target_group" "tg1" {
  name     = "tg-1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.public_subnet.outputs.vpc_id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-299"
  }

  tags = merge(
    local.default_tags,
    { "Name" = "${var.prefix}-tg-1" }
  )
}

resource "aws_lb_target_group" "tg2" {
  name     = "tg-2"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.public_subnet.outputs.vpc_id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-299"
  }

  tags = merge(
    local.default_tags,
    { "Name" = "${var.prefix}-tg-2" }
  )
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.main_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg1.arn
  }
}

# Attach instance 1 (index 0)
# Attach instances 1 and 3 to target group tg1
#resource "aws_lb_target_group_attachment" "tg1_attach" {
#  count            = 2
#  target_group_arn = aws_lb_target_group.tg1.arn
#  target_id        = aws_instance.acs73026[count.index].id
#  port             = 80
#}



