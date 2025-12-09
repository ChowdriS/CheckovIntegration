variable "region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

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
resource "aws_vpc" "chow321-vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "chow321-vpc"
    }
}

resource "aws_subnet" "chow321-vpc-public-subnet" {
    vpc_id = aws_vpc.chow321-vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "${var.region}a"
    tags = {
        Name = "chow321-public-subnet"
    }
}

resource "aws_internet_gateway" "chow321-igw" {
  vpc_id = aws_vpc.chow321-vpc.id
  tags = {
    Name = "chow321-igw"
  }
}

resource "aws_route_table" "chow321-vpc-routetable" {
  vpc_id = aws_vpc.chow321-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.chow321-igw.id
  }

  tags = {
    Name = "chow321-vpc-routetable"
  }
}

resource "aws_route_table_association" "chow321-public-subnet-assoc-to-routetable" {
  subnet_id      = aws_subnet.chow321-vpc-public-subnet.id
  route_table_id = aws_route_table.chow321-vpc-routetable.id
}

resource "aws_security_group" "chow321-sg" {
    name        = "chow321-sg"
    vpc_id      = aws_vpc.chow321-vpc.id
    
    tags = {
        Name = "chow321-sg"
    }
  
}

resource "aws_security_group_rule" "Allow-inbound-http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.chow321-sg.id
}

resource "aws_security_group_rule" "Allow-inbound-ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.chow321-sg.id
}

resource "aws_security_group_rule" "Allow-all-outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 65355
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.chow321-sg.id
}


resource "aws_instance" "chow321-vm" {
  ami                         = "ami-07860a2d7eb515d9a"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.chow321-vpc-public-subnet.id
  vpc_security_group_ids      = [aws_security_group.chow321-sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y nginx
    echo "Hello, World from $(hostname -f)" | sudo tee /usr/share/nginx/html/index.html
    sudo systemctl start nginx
    sudo systemctl enable nginx
  EOF

  tags = {
    Name = "chow321-vm"
  }
}


output "vpc_id" {
  value = aws_vpc.chow321-vpc.id
}

output "vm-public-ip" {
  value = aws_instance.chow321-vm.public_ip
}
