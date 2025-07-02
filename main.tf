data "aws_caller_identity" "default" {}
data "aws_region" "default" {}

resource "aws_sns_topic" "main" {
  name = "${var.project}-${var.environment}-notifications"
}

resource "aws_sns_topic_policy" "alarm" {
  arn    = aws_sns_topic.main.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

locals {
  notification_lambda_name         = "${var.project}-${var.environment}-notification"
  notification_lambda_zip_filename = "${path.module}/notification.zip"
}

data "archive_file" "notification" {
  type             = "zip"
  source_dir       = "${path.module}/python_code"
  output_path      = local.notification_lambda_zip_filename
  output_file_mode = "0755"
}

resource "aws_lambda_function" "notification" {
  function_name    = local.notification_lambda_name
  role             = aws_iam_role.notification.arn
  filename         = local.notification_lambda_zip_filename
  handler          = "main.lambda_handler"
  runtime          = "python3.13"
  timeout          = 3
  memory_size      = 128
  tags             = var.tags
  source_code_hash = data.archive_file.notification.output_base64sha256

  depends_on = [
    aws_iam_role.notification,
    aws_cloudwatch_log_group.notification
  ]
  environment {
    variables = {
      WEBHOOKS = join(",", aws_ssm_parameter.webhooks.*.arn)
    }
  }
}

resource "aws_cloudwatch_log_group" "notification" {
  name              = "/aws/lambda/${local.notification_lambda_name}"
  retention_in_days = var.log_retention
  tags              = var.tags
}


################################################
#### IAM                                    ####
################################################

resource "aws_iam_role" "notification" {
  name               = "${local.notification_lambda_name}-${data.aws_region.default.id}"
  description        = "Role used for lambda function ${local.notification_lambda_name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_notification.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "notification" {
  name   = "${local.notification_lambda_name}-policy"
  policy = data.aws_iam_policy_document.role_notification.json
  role   = aws_iam_role.notification.id
}

data "aws_iam_policy_document" "assume_role_notification" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "role_notification" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "${aws_cloudwatch_log_group.notification.arn}*"
    ]
  }
  statement {
    actions = [
      "ssm:GetParameter"
    ]

    resources = aws_ssm_parameter.webhooks.*.arn

  }

}

resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.main.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.notification.arn
}

resource "aws_lambda_permission" "sns" {
  statement_id  = "AllowExecutionFromSNSErrors"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notification.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.main.arn
}

resource "aws_ssm_parameter" "webhooks" {
  count = length(var.webhooks)
  name  = "/${var.project}/${var.environment}/webhooks/${count.index}"
  type  = "SecureString"
  value = var.webhooks[count.index]
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    effect = "Allow"
    resources = [
      aws_sns_topic.main.arn
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        data.aws_caller_identity.default.account_id
      ]
    }
  }

  statement {
    sid     = "Allow CloudwatchEvents"
    actions = ["sns:Publish"]
    resources = [
      aws_sns_topic.main.arn
    ]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }

  statement {
    sid     = "Allow RDS Event Notification"
    actions = ["sns:Publish"]
    resources = [
      aws_sns_topic.main.arn
    ]

    principals {
      type        = "Service"
      identifiers = ["rds.amazonaws.com"]
    }
  }
}