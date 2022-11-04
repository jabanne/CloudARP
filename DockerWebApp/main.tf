terraform {
  cloud {
    organization = "JulieTest"
    workspaces {
      name = "DockerWebApp"
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

resource "aws_iam_role" "beanstalk_service" {
  name = "beanstalk_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "beanstalkattach" {
  role       = aws_iam_role.beanstalk_service.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_instance_profile" "beanstalk_profile" {
  name = "beanstalk_profile"
  role = aws_iam_role.beanstalk_service.name
}

resource "aws_s3_bucket" "docker" {
  bucket = "dockerwebapptest"
}

resource "aws_s3_object" "docker" {
  bucket = aws_s3_bucket.docker.id
  key    = "dockerapp.zip"
  source = "dockerapp.zip"
}

resource "aws_elastic_beanstalk_application" "docker" {
  name = "dockerwebapptest"
}

resource "aws_elastic_beanstalk_environment" "docker" {
  name                = "dockertestenv"
  application         = aws_elastic_beanstalk_application.docker.name
  solution_stack_name = "64bit Amazon Linux 2 v3.5.0 running Docker"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.beanstalk_profile.arn
  }

}

resource "aws_elastic_beanstalk_application_version" "docker" {
  name        = "dockerwebapptest"
  application = aws_elastic_beanstalk_application.docker.name
  bucket      = aws_s3_bucket.docker.id
  key         = aws_s3_object.docker.id
}


