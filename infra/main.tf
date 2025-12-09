variable "region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

provider "aws" {
  region = var.region
}

resource "aws_instance" "example" {
  ami           = "ami-08c40ec9ead489470"
  instance_type = var.instance_type

  tags = {
    Name = "chow3-infra-check"
  }
}

output "public_ip" {
  value = aws_instance.example.private_ip
}
