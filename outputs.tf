output "sns_arn" {
  value       = aws_sns_topic.main.arn
  description = "arn of the webhook connected sns topic"
}