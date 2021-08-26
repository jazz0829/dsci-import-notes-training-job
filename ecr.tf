data "aws_ecr_repository" "import_notes_rgs_classification" {
  count = "${local.name_prefix == "dd" ? 1 : 0}"

  name = "${var.ecr_repo_name}"
}

resource "aws_ecr_repository_policy" "repository_policy" {
  count = "${local.name_prefix == "dd" ? 1 : 0}"

  repository = "${var.ecr_repo_name}"

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "AllowPullToAllDSCIAccounts",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${var.accountid}:root",
                "AWS": "arn:aws:iam::809521787705:root",
                "AWS": "arn:aws:iam::131239767718:root"
            },
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability"
            ]
        },
        {
          "Sid": "DenyDelete",
          "Effect": "Deny",
          "Principal": "*",
          "Action": [
            "ecr:BatchDeleteImage"
          ]
        }
    ]
}
EOF
}

resource "aws_ecr_lifecycle_policy" "import_notes_rgs_classification_lifecycle_policy" {
  count = "${local.name_prefix == "dd" ? 1 : 0}"

  repository = "${var.ecr_repo_name}"

  policy = <<EOF
{
"rules": [
    {
      "action": {
        "type": "expire"
      },
      "selection": {
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 3,
        "tagStatus": "tagged",
        "tagPrefixList": [
          "train-pr-"
        ]
      },
      "description": "Remove train-pr images",
      "rulePriority": 1
    },
    {
      "action": {
        "type": "expire"
      },
      "selection": {
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 3,
        "tagStatus": "tagged",
        "tagPrefixList": [
          "serve-pr"
        ]
      },
      "description": "Remove serve-pr images",
      "rulePriority": 2
    },
    {
      "action": {
        "type": "expire"
      },
      "selection": {
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 3,
        "tagStatus": "tagged",
        "tagPrefixList": [
          "train-branch-"
        ]
      },
      "description": "Remove train-branch images",
      "rulePriority": 3
    },
    {
      "action": {
        "type": "expire"
      },
      "selection": {
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 3,
        "tagStatus": "tagged",
        "tagPrefixList": [
          "serve-branch"
        ]
      },
      "description": "Remove serve-branch images",
      "rulePriority": 4
    },
    {
      "action": {
        "type": "expire"
      },
      "selection": {
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 3,
        "tagStatus": "untagged"
      },
      "description": "Remove Untagged images",
      "rulePriority": 5
    }
  ]
}
EOF
}
