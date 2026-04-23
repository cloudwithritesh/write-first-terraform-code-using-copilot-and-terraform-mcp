variable "subscription_id" {
  description = "The Azure subscription ID where resources will be deployed."
  type        = string
  sensitive   = true
}

variable "location" {
  description = "The Azure region where resources will be created."
  type        = string
  default     = "southeastasia"
}

variable "environment" {
  description = "The deployment environment. Must be one of: dev, staging, prod."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "The name of the project. Used as a prefix for resource names. Must be at least 3 characters."
  type        = string

  validation {
    condition     = length(var.project_name) >= 3
    error_message = "The project_name must be at least 3 characters long to produce a valid storage account name."
  }
}

variable "owner" {
  description = "The team or individual responsible for these resources."
  type        = string
  default     = "platform-team"
}
