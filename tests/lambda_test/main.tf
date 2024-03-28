provider "aws" {
  region = "eu-west-1"

  assume_role {
    role_arn = "arn:aws:iam::246402711611:role/AdministratorAccess"
  }
}


data "aws_caller_identity" "default" {}
data "aws_region" "default" {}

resource "random_uuid" "lambda_id" {
}

locals {
  test_lambda_name         = "${random_uuid.lambda_id.result}-test"
  test_lambda_zip_filename = "${path.module}/test.zip"
}

data "archive_file" "test" {
  type             = "zip"
  source_file      = "${path.module}/main.py"
  output_path      = local.test_lambda_zip_filename
  output_file_mode = "0755"
}

resource "aws_lambda_function" "test" {
  function_name    = local.test_lambda_name
  role             = aws_iam_role.test.arn
  filename         = local.test_lambda_zip_filename
  handler          = "main.lambda_handler"
  runtime          = "python3.9"
  timeout          = 3
  memory_size      = 128
  source_code_hash = data.archive_file.test.output_base64sha256

  depends_on = [
    aws_iam_role.test,
    #    aws_cloudwatch_log_group.test
  ]
  environment {
    variables = {
      SSM = aws_ssm_parameter.test_result_param.name
    }
  }
}
#
#resource "aws_cloudwatch_log_group" "test" {
#  name              = "/aws/lambda/${local.test_lambda_name}"
#  retention_in_days = 7
#}


################################################
#### IAM                                    ####
################################################

resource "aws_iam_role" "test" {
  name               = "${local.test_lambda_name}-role"
  description        = "Role used for lambda function ${local.test_lambda_name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_test.json
  #  tags               = var.tags
}

resource "aws_iam_role_policy" "test" {
  name   = "${local.test_lambda_name}-policy"
  policy = data.aws_iam_policy_document.role_test.json
  role   = aws_iam_role.test.id
}

data "aws_iam_policy_document" "assume_role_test" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "role_test" {
  #  statement {
  #    actions = [
  #      "logs:CreateLogStream",
  #      "logs:PutLogEvents"
  #    ]
  #
  #    resources = [
  #      "${aws_cloudwatch_log_group.test.arn}*"
  #    ]
  #  }
  statement {
    actions = [
      "ssm:PutParameter"
    ]

    resources = [
      aws_ssm_parameter.test_result_param.arn
    ]
  }
}

resource "aws_lambda_function_url" "function" {
  function_name      = aws_lambda_function.test.function_name
  authorization_type = "NONE"
}

resource "aws_ssm_parameter" "test_result_param" {
  name  = local.test_lambda_name
  type  = "String"
  value = "NONE"
}

output "url" {
  value = aws_lambda_function_url.function.function_url
}

output "ssm" {
  value = aws_ssm_parameter.test_result_param.arn
}
