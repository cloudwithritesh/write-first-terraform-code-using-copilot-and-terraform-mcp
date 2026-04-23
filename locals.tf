locals {
  prefix               = "${var.project_name}-${var.environment}"
  storage_account_name = substr(lower(replace("${var.project_name}${var.environment}sa", "-", "")), 0, 24)

  common_tags = {
    environment = var.environment
    project     = var.project_name
    owner       = var.owner
    managed_by  = "terraform"
  }
}
