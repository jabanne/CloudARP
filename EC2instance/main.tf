terraform {
  cloud {
    organization = "JulieTest"
    workspaces {
      name = "EC2-tests"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-west-2"
}
resource "aws_instance" "web" {
  ami           = "ami-017fecd1353bcc96e"
  instance_type = "t2.micro"

  user_data = <<-EOL
  #! /bin/bash -xe
  
  apt update
  apt install net-tools
EOL

  tags = {
    name = "HelloWorld"
  }
  /*connection {
    type     = "ssh"
    user     = "root"
    password = "test"
    host     = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "apt install net-tools",
    ]
  } */
}
