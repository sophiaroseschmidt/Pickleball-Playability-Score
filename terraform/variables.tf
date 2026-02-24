variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "finance-project"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"  # Change to your preferred region
}

variable "db_admin_username" {
  description = "PostgreSQL admin username"
  type        = string
  default     = "pgadmin"
}

variable "db_admin_password" {
  description = "PostgreSQL admin password"
  type        = string
  sensitive   = true
}

variable "allowed_ip_addresses" {
  description = "List of IP addresses allowed to access the database"
  type        = list(string)
  default     = []  # Add your IP here
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Project     = "Finance Data Pipeline"
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}

variable "name_prefix" {
  default     = "postgresqlfs"
  description = "Prefix of the resource name."
}

variable "location" {
  default     = "eastus"
  description = "Location of the resource."
}