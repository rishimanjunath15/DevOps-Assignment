variable "location" {
  description = "Azure region for the state storage resources"
  type        = string
  default     = "centralindia"
}

variable "environments" {
  description = "List of environments to create state storage for"
  type        = list(string)
  default     = ["dev", "staging", "prod"]
}
