terraform {
  cloud {
    organization = "JulieTest"
    workspaces {
      name = "learn-tfc-aws"
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

resource "aws_iam_group_membership" "team" {
  name = var.team

  users = [
    aws_iam_user.user1.name,
    aws_iam_user.user2.name,
    aws_iam_user.user3.name
  ]

  group = aws_iam_group.group.name
}

resource "aws_iam_group" "group" {
  name = var.groupname
}

resource "aws_iam_policy" "policy" {
  name        = "adminpolicy"
  description = "administrator access"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "*",
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "attachadmin" {
  group      = aws_iam_group.group.name
  policy_arn = aws_iam_policy.policy.arn

}

resource "aws_iam_user" "user1" {
  name = var.user1
}

resource "aws_iam_user_login_profile" "user1" {
  user            = aws_iam_user.user1.name
  password_length = 8
}

output "pw1" {
  value = aws_iam_user_login_profile.user1.password
}

resource "aws_iam_user" "user2" {
  name = var.user2
}
resource "aws_iam_user_login_profile" "user2" {
  user            = aws_iam_user.user2.name
  password_length = 8
}

output "pw2" {
  value = aws_iam_user_login_profile.user2.password
}

resource "aws_iam_user" "user3" {
  name = var.user3
}
resource "aws_iam_user_login_profile" "user3" {
  user            = aws_iam_user.user3.name
  password_length = 8
}

output "pw3" {
  value = aws_iam_user_login_profile.user3.password
}

# added to instantiate Ubuntu VM of type t2.micro on AWS 
#comment out below unless needed
/*resource "aws_instance" "web" {
  ami           = "ami-017fecd1353bcc96e"
  instance_type = "t2.micro"

  tags = {
    name = "HelloWorld"
  }
  } */


