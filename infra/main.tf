#############
# VARIABLES #
#############

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

###########
# PROVIDER #
###########

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

############
#   VPC    #
############

resource "aws_vpc" "chow321_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "chow321-vpc"
  }
}

######################
# PUBLIC SUBNET      #
######################

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.chow321_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.region}a"

  tags = {
    Name = "chow321-public-subnet"
  }
}

###############################
# INTERNET GATEWAY            #
###############################

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.chow321_vpc.id

  tags = {
    Name = "chow321-igw"
  }
}

###############################
# ROUTE TABLE + ASSOCIATION   #
###############################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.chow321_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "chow321-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}

##########################
# SECURITY GROUP         #
##########################

resource "aws_security_group" "sg" {
  name   = "chow321-sg"
  vpc_id = aws_vpc.chow321_vpc.id

  tags = {
    Name = "chow321-sg"
  }
}

# Allow HTTP (80)
resource "aws_security_group_rule" "http_in" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg.id
}

# Allow SSH (22) - BEST PRACTICE: restrict to your IP
resource "aws_security_group_rule" "ssh_in" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # Replace with your IP for production!
  security_group_id = aws_security_group.sg.id
}

# Allow ALL outbound
resource "aws_security_group_rule" "all_out" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg.id
}

###################
# EC2 INSTANCE    #
###################

resource "aws_instance" "vm" {
  ami                         = "ami-07860a2d7eb515d9a" # Amazon Linux 2023
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y nginx
    echo "Hello, World from $(hostname -f)" > /usr/share/nginx/html/index.html
    systemctl start nginx
    systemctl enable nginx
  EOF

  tags = {
    Name = "chow321-vm"
  }
}

##########
# OUTPUTS #
##########

output "vpc_id" {
  value = aws_vpc.chow321_vpc.id
}

output "vm_public_ip" {
  value = aws_instance.vm.public_ip
}
