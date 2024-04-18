provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "MyVPC" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "MyVPC"
  }
}

resource "aws_security_group" "Mysg" {
  name        = "Mysg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.MyVPC.id

  # Dynamic block for ingress rules
  dynamic "ingress" {
    for_each = var.web_ingress
    content {
      description = "TLS from VPC"
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_block  # corrected from cidr_blocks to cidr_block
    }
  }

  # Egress rule
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Mysg"
  }
}

variable "web_ingress" {
  type = map(object({
    port       = number
    protocol   = string
    cidr_block = list(string)
  }))
  default = {
    "80" = {
      port       = 80
      protocol   = "tcp"
      cidr_block = ["0.0.0.0/0"]
    },
    "443" = {
      port       = 443
      protocol   = "tcp"
      cidr_block = ["0.0.0.0/0"]
    }
  }
}

resource "aws_network_acl" "Mynacl" {
  vpc_id = aws_vpc.MyVPC.id

  egress {
    protocol    = "tcp"
    rule_no     = 100  # Correct attribute name is rule_no, not rule_number
    action      = "allow"  # Correct attribute name is action, not rule_action
    cidr_block  = "0.0.0.0/0"
    from_port   = 443
    to_port     = 443
  }
  
  # Dynamic block for ingress rules
  dynamic "ingress" {
    for_each = var.app_ingress
    content {
      protocol    = ingress.value.protocol
      rule_no     = tonumber(ingress.key)  # Correct attribute name is rule_no
      action      = "allow"  # Correct attribute name is action
      cidr_block  = ingress.value.cidr_block[0]  # Assuming each entry has at least one CIDR block
      from_port   = ingress.value.port
      to_port     = ingress.value.port
    }
  }

  tags = {
    Name = "Mynacl"
  }
}

variable "app_ingress" {
  type = map(object({
    port       = number
    protocol   = string
    cidr_block = list(string)
  }))
  default = {
    "100" = {
      port       = 100,
      protocol   = "tcp",
      cidr_block = ["0.0.0.0/0"]
    } 
  }
}