variable "project_name" {
  type        = string
  description = "Prefix identifier for resources"
  default     = "dbx-demo"
}

variable "environment_prefix" {
  type        = string
  description = "Environment identifier"
  default     = "cicd"
}

variable "location" {
  type        = string
  description = "Azure region for the resources"
  default     = "eastus"
}

variable "sku" {
  type        = string
  description = "Pricing tier for Databricks (standard or premium). 'premium' is required for Unity Catalog, MLflow Governance, and AI Agents."
  default     = "premium"
  validation {
    condition     = contains(["standard", "premium"], var.sku)
    error_message = "SKU must be either 'standard' or 'premium'."
  }
}

variable "tags" {
  type        = map(string)
  description = "Common tags for tracking and cost management"
  default = {
    Owner     = "Demo"
    ManagedBy = "Terraform"
    Purpose   = "CICD-Demo"
  }
}
