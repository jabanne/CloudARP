terraform {
  cloud {
    organization = "JulieTest"
    workspaces {
      name = "CloudARP"
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

resource "aws_iam_group" "group" {
name = "Supporters"
}

/*resource "aws_iam_group_policy_attachment" "attachsupport" {
group = aws_iam_group.group.name
policy_arn = "arn:aws:iam::aws:policy/job-function/SupportUser"
} */


