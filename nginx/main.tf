terraform {
  cloud {
    organization = "JulieTest"
    workspaces {
      name = "nginx-test"
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

resource "aws_vpc" "nginx-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  enable_classiclink   = "false"
  instance_tenancy     = "default"
}

resource "aws_subnet" "prod-subnet-public-1" {
  vpc_id                  = aws_vpc.nginx-vpc.id // Referencing the id of the VPC from abouve code block
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true" // Makes this a public subnet
  availability_zone       = "us-west-2a"
}

resource "aws_internet_gateway" "prod-igw" {
  vpc_id = aws_vpc.nginx-vpc.id
}

resource "aws_route_table" "prod-public-crt" {
  vpc_id = aws_vpc.nginx-vpc.id
  route {
    cidr_block = "0.0.0.0/0"                      //associated subnet can reach everywhere
    gateway_id = aws_internet_gateway.prod-igw.id //CRT uses this IGW to reach internet
  }
  tags = {
    Name = "prod-public-crt"
  }
}

resource "aws_route_table_association" "prod-crta-public-subnet-1" {
  subnet_id      = aws_subnet.prod-subnet-public-1.id
  route_table_id = aws_route_table.prod-public-crt.id
}

resource "aws_security_group" "ssh-allowed" {
  vpc_id = aws_vpc.nginx-vpc.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] // Ideally best to use your machines' IP. However if it is dynamic you will need to change this in the vpc every so often. 
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "aws-key" {
  key_name   = "aws-key"
  public_key = file(var.PUBLIC_KEY_PATH) // Path is in the variables file
}

resource "aws_instance" "nginx_server" {
  ami           = "ami-08d70e59c07c61a3a"
  instance_type = "t2.micro"
  tags = {
    Name = "nginx_server"
  }

  # VPC
  subnet_id = aws_subnet.prod-subnet-public-1.id

  # Security Group
  vpc_security_group_ids = ["${aws_security_group.ssh-allowed.id}"]

  # the Public SSH key
  key_name = aws_key_pair.aws-key.id

  # nginx installation
  # storing the nginx.sh file in the EC2 instance
  provisioner "file" {
    source      = "nginx.sh"
    destination = "nginx.sh"

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ubuntu"
      private_key = file("${var.PRIVATE_KEY_PATH}")
    }
  }

  # Executing the nginx.sh file
  # changing ownership of html directory and index html file to ubuntu to make changes  
  provisioner "remote-exec" {
    inline = [
      "chmod +x ~/nginx.sh",
      "sudo ./nginx.sh",
      "cd /var/www",
      "sudo chown ubuntu:ubuntu html",
      "cd html",
      "sudo chown ubuntu:ubuntu index.nginx-debian.html"
    ]
  }
  # replacing default html index file with own file using provisioner so that web page is our own
  provisioner "file" {
    source      = "index.nginx-debian.html"
    destination = "/var/www/html/index.nginx-debian.html"

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ubuntu"
      private_key = file("${var.PRIVATE_KEY_PATH}")
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo service nginx start"
    ]
  }


  # Setting up the ssh connection to install the nginx server
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file("${var.PRIVATE_KEY_PATH}")
  }
}
