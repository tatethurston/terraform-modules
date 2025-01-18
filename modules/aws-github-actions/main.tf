terraform {
  required_version = "~> 1.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_iam_openid_connect_provider" "github_action" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [var.thumbprint]
  url             = "https://token.actions.githubusercontent.com"

  tags = {
    Environment = "Production"
    Name        = "AWS Github Actions"
    Project     = var.project
  }
}

resource "aws_iam_role" "github_action" {
  name = "Github-Action"

  description = "Role assumed by Github Actions."

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/IAMFullAccess",
    "arn:aws:iam::aws:policy/PowerUserAccess"
  ]

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : aws_iam_openid_connect_provider.github_action.arn
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com"
          },
          "StringLike" : {
            "token.actions.githubusercontent.com:sub" : "repo:${var.repo}/*"
          }
        }
      }
    ]
  })

  tags = {
    Environment = "Production"
    Name        = "AWS Github Actions"
    Project     = var.project
  }
}
