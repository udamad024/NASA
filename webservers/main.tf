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

resource "aws_instance" "acs73026" {
  count                       = 3
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.Assignment.key_name
  security_groups             = [aws_security_group.acs730w7.id]
  subnet_id                   = element(
                                  data.terraform_remote_state.public_subnet.outputs.public_subnet_ids,
                                  (count.index + (count.index >= 1 ? 1 : 0))
                                )
  associate_public_ip_address = true
  user_data = file("${path.module}/install_httpd.sh")
  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.default_tags,
    {
      "Name" = "Webserver ${count.index == 0 ? 1 : (count.index == 1 ? 3 : 4)}",
      "WebServerGroup" = count.index >= 1 ? "Ansible" : ""
    }
  )
}


# Adding SSH  key to instance
resource "aws_key_pair" "Assignment" {
  key_name   = var.prefix
  public_key = file("${var.env}.pub")
}

#security Group
resource "aws_security_group" "acs730w7" {
  name        = "allow_http_ssh"
  description = "Allow HTTP and SSH inbound traffic"
  vpc_id      = data.terraform_remote_state.public_subnet.outputs.vpc_id

  ingress {
    description      = "HTTP from everywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "SSH from everywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.default_tags,
    {
      "Name" = "${var.prefix}-EBS"
    }
  )
}


# - end 


# Bastion host
resource "aws_instance" "bastion_host" {
  ami                    = data.aws_ami.latest_amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = data.terraform_remote_state.public_subnet.outputs.public_subnet_ids[1] # Choose the second public subnet
  key_name               = aws_key_pair.Assignment.key_name
  security_groups     = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true

  tags = merge(local.default_tags,
    {
      "Name" = "Webserver2"
    }
  )
}

# VMs in private subnets
resource "aws_instance" "vm_instances" {
  count                  = length(data.terraform_remote_state.public_subnet.outputs.private_subnets_ids)
  ami                    = data.aws_ami.latest_amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = data.terraform_remote_state.public_subnet.outputs.private_subnets_ids[count.index]
  key_name               = aws_key_pair.Assignment.key_name
  security_groups        = [aws_security_group.vm_sg.id]

  tags = merge(local.default_tags,
    {
      "Name" = "${var.prefix}-private-${count.index + 5}"
    }
  )
}

resource "aws_security_group" "bastion_sg" {
  vpc_id = data.terraform_remote_state.public_subnet.outputs.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

# Create security group for VMs
resource "aws_security_group" "vm_sg" {
  vpc_id = data.terraform_remote_state.public_subnet.outputs.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

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
resource "aws_lb_target_group_attachment" "tg1_attach" {
  count            = 2
  target_group_arn = aws_lb_target_group.tg1.arn
  target_id        = aws_instance.acs73026[count.index].id
  port             = 80
}



