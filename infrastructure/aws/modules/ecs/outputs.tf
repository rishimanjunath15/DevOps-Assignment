output "cluster_id" {
  description = "ECS cluster ID"
  value       = aws_ecs_cluster.main.id
}

output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.main.arn
}

output "backend_service_name" {
  description = "ECS service name for the backend"
  value       = aws_ecs_service.backend.name
}

output "frontend_service_name" {
  description = "ECS service name for the frontend"
  value       = aws_ecs_service.frontend.name
}

output "backend_task_definition_arn" {
  description = "Backend task definition ARN"
  value       = aws_ecs_task_definition.backend.arn
}

output "frontend_task_definition_arn" {
  description = "Frontend task definition ARN"
  value       = aws_ecs_task_definition.frontend.arn
}

output "ecs_tasks_security_group_id" {
  description = "Security group ID attached to ECS tasks"
  value       = aws_security_group.ecs_tasks.id
}

output "task_execution_role_arn" {
  description = "ECS task execution IAM role ARN"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "task_role_arn" {
  description = "ECS task IAM role ARN"
  value       = aws_iam_role.ecs_task.arn
}

output "backend_log_group" {
  description = "CloudWatch log group for backend"
  value       = aws_cloudwatch_log_group.backend.name
}

output "frontend_log_group" {
  description = "CloudWatch log group for frontend"
  value       = aws_cloudwatch_log_group.frontend.name
}

output "backend_autoscaling_target_resource_id" {
  description = "Auto scaling resource ID for the backend service (null when autoscaling disabled)"
  value       = var.enable_autoscaling ? aws_appautoscaling_target.backend[0].resource_id : null
}

output "frontend_autoscaling_target_resource_id" {
  description = "Auto scaling resource ID for the frontend service (null when autoscaling disabled)"
  value       = var.enable_autoscaling ? aws_appautoscaling_target.frontend[0].resource_id : null
}
