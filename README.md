# sns-notifications <a href="https://miquido.com"><img align="right" src="https://cdn.miquido.dev/miquido-logo.png" width="150" /></a>

Terraform module that creates an SNS topic and forwards messages to webhooks via Lambda

## Development

```bash
make init   # run once after cloning
make readme # regenerate README.md
make lint   # lint terraform code
```

## Usage

```hcl
module "sns_notifications" {
  source = "git@gitlab.miquido.com:miquido/terraform/sns-notifications.git"

  environment = "production"
  project     = "my-project"
  webhooks    = ["https://hooks.example.com/my-webhook"]

  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_archive"></a> [archive](#provider\_archive) | 2.8.0 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.60.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_default_formatter"></a> [default\_formatter](#module\_default\_formatter) | git::https://github.com/miquido/terraform-default-sns-formatter.git | tags/v1.1.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudwatch_log_group.notification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_role.notification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.notification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_lambda_function.notification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.sns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_sns_topic.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_sns_topic_subscription.lambda_subscription](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_ssm_parameter.webhooks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_message_formatter_lambdas"></a> [additional\_message\_formatter\_lambdas](#input\_additional\_message\_formatter\_lambdas) | List of additional AWS Lambdas to format the message | `list(string)` | `[]` | no |
| <a name="input_default_message_formatters"></a> [default\_message\_formatters](#input\_default\_message\_formatters) | List of included default message formatters | `list(string)` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name | `any` | n/a | yes |
| <a name="input_log_retention"></a> [log\_retention](#input\_log\_retention) | How long to keep logs | `number` | `7` | no |
| <a name="input_project"></a> [project](#input\_project) | Project name | `any` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Default tags to apply on all created resources | `map(string)` | `{}` | no |
| <a name="input_webhooks"></a> [webhooks](#input\_webhooks) | List of webhooks to call when SNS message is received | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_sns_arn"></a> [sns\_arn](#output\_sns\_arn) | arn of the webhook connected sns topic |
<!-- END_TF_DOCS -->

## License

[MIT](LICENSE)
