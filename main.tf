resource "aws_sns_topic" "main" {
  name = "${var.project}-${var.environment}-notifications"
}

locals {
  notification_lambda_name         = "${var.project}-${var.environment}-notification"
  notification_lambda_zip_filename = "${path.module}/notification.zip"
}

data "archive_file" "notification" {
  type             = "zip"
  source_dir      = "${path.module}/python_code"
  output_path      = local.notification_lambda_zip_filename
  output_file_mode = "0755"
}

resource "aws_lambda_function" "notification" {
  function_name    = local.notification_lambda_name
  role             = aws_iam_role.notification.arn
  filename         = local.notification_lambda_zip_filename
  handler          = "main.lambda_handler"
  runtime          = "python3.9"
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
  name               = "${local.notification_lambda_name}-role"
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
  statement {
    actions = [
      "kms:Decrypt"
    ]

    resources = ["arn:aws:kms:eu-central-1:246402711611:key/bc1169d3-442a-4aa3-b091-e16bea5afb22"]

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
