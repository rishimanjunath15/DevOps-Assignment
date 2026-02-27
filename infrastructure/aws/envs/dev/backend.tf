# Backend configuration for dev environment
terraform {
  backend "s3" {
    bucket         = "devops-assignment-tf-state-655024857157"
    key            = "aws/dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
