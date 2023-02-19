variable "region" {
  type        = string
  description = "AWS Region"
  default     = ["us-east-1"]
}

variable "environment" {
  type        = string
  description = "Type of environment"
}
