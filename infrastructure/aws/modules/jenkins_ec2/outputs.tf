output "instance_id" {
  description = "Jenkins EC2 instance ID"
  value       = aws_instance.jenkins.id
}

output "public_ip" {
  description = "Public IP address of Jenkins instance"
  value       = aws_instance.jenkins.public_ip
}

output "private_ip" {
  description = "Private IP address of Jenkins instance"
  value       = aws_instance.jenkins.private_ip
}

output "public_dns" {
  description = "Public DNS name of Jenkins instance"
  value       = aws_instance.jenkins.public_dns
}

output "elastic_ip" {
  description = "Elastic IP address (if enabled)"
  value       = var.enable_elastic_ip ? aws_eip.jenkins[0].public_ip : aws_instance.jenkins.public_ip
}

output "jenkins_url" {
  description = "Jenkins web UI URL"
  value       = var.enable_elastic_ip ? "http://${aws_eip.jenkins[0].public_ip}:8080" : "http://${aws_instance.jenkins.public_ip}:8080"
}

output "jenkins_url_dns" {
  description = "Jenkins web UI URL using public DNS"
  value       = "http://${aws_instance.jenkins.public_dns}:8080"
}

output "security_group_id" {
  description = "Security group ID for Jenkins"
  value       = aws_security_group.jenkins.id
}

output "iam_role_name" {
  description = "IAM role name for Jenkins"
  value       = aws_iam_role.jenkins.name
}

output "iam_instance_profile_name" {
  description = "IAM instance profile name"
  value       = aws_iam_instance_profile.jenkins.name
}
