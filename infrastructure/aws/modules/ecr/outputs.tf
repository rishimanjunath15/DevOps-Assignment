output "repository_urls" {
  description = "Map of repository name to URL (use for docker push)"
  value       = { for k, v in aws_ecr_repository.this : k => v.repository_url }
}

output "repository_arns" {
  description = "Map of repository name to ARN (use for IAM policies)"
  value       = { for k, v in aws_ecr_repository.this : k => v.arn }
}

output "frontend_url" {
  description = "ECR URL for the frontend image"
  value       = aws_ecr_repository.this["frontend"].repository_url
}

output "backend_url" {
  description = "ECR URL for the backend image"
  value       = aws_ecr_repository.this["backend"].repository_url
}

output "registry_id" {
  description = "AWS account ID (ECR registry ID)"
  value       = aws_ecr_repository.this["frontend"].registry_id
}
