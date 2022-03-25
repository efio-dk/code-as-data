### KMS CMK ###

output "kms_key_id" {
  description = "The id of the KMS CMK key used by the solution."
  value       = aws_kms_key.this.id
}

output "kms_key_arn" {
  description = "The id of the KMS CMK key used by the solution."
  value       = aws_kms_key.this.arn
}

output "kms_key_alias" {
  description = "The alias of the KMS CMK key used by the solution."
  value       = aws_kms_alias.this.name
}

### ECR ###

output "ecr_arn" {
  description = "The arn of the container registry repository"
  value       = { for k, v in aws_ecr_repository.registry : k => v.arn }
}

output "ecr_registry_id" {
  description = "The arn of the container registry repository"
  value       = { for k, v in aws_ecr_repository.registry : k => v.registry_id }
}

output "ecr_repository_url" {
  description = "The url of the container registry repository"
  value       = { for k, v in aws_ecr_repository.registry : k => v.repository_url }
}

### CICD ###

output "codepipeline_arn" {
  description = "The arn of the AWS CodePipeeline"
  value       = aws_codepipeline.cicd.arn
}

output "codepipeline_id" {
  description = "The id of the AWS CodePipeeline"
  value       = aws_codepipeline.cicd.id
}

output "codebuild_function_arns" {
  description = "The arns of the function codebuild projects"
  value       = { for k, v in aws_codebuild_project.build : k => v.arn }
}

### SNS Topics ###

output "sns_arns" {
  description = "The arns of the sns topics created."
  value       = { for k, v in aws_sns_topic.topic : k => v.arn }
}

### SQS Queues ###

output "sqs_arns" {
  description = "The arns of the sqs queues created."
  value       = { for k, v in aws_sqs_queue.queue : k => v.arn }
}

output "sqs_urls" {
  description = "The urls of the sqs queues created."
  value       = { for k, v in aws_sqs_queue.queue : k => v.url }
}

### Lambda ###

output "cloudwatch_log_group_arns" {
  description = "The arns of the lambda cloudwatch log groups for the serverless application."
  value       = { for k, v in aws_cloudwatch_log_group.function : k => v.arn }
}

output "cloudwatch_log_group_names" {
  description = "The names of the lambda cloudwatch log groups for the serverless application."
  value       = { for k, v in aws_cloudwatch_log_group.function : k => v.name }
}

output "iam_role_arns" {
  description = "The arns of the lambda iam roles for the serverless application."
  value       = { for k, v in aws_iam_role.function : k => v.arn }
}

output "iam_role_names" {
  description = "The arns of the lambda iam roles for the serverless application."
  value       = { for k, v in aws_iam_role.function : k => v.name }
}

### Debug purpose ###


output "xxx" {
  value = ""
}
output "yyy" {
  value = ""
}
output "zzz" {
  value = ""
}