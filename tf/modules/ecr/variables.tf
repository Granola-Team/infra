variable "region" {
  type        = string
  description = "AWS Region"
  default     = "ca-central-1"
}

variable "environment" {
  type        = string
  description = "Type of environment"
}

variable "ecr_name" {
  type        = string
  description = "The name of the ECR repo"
}

variable "ecr_image_tag_mutability" {
  type        = string
  description = "The tag mutability setting for the repository. Must be one of: MUTABLE or IMMUTABLE. Defaults to MUTABLE."
  default     = "IMMUTABLE"
}
