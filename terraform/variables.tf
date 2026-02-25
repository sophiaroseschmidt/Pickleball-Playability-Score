// Default
// **********************************

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

variable "resource_group" {
  description = "Name of Azure resource group"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "North Central US"  # Change to your preferred region
}

// **********************************

// PostgreSQL
// **********************************

variable "db_admin_username" {
  description = "PostgreSQL admin username"
  type        = string
 
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

variable "budget_alert_email" {
  description = "Email address to receive budget alerts"
  type        = string
}

// Snowflake
// **********************************

variable "snowflake_account" {
  description = "Snowflake account identifier (format: orgname-accountname)"
  type        = string
}

variable "snowflake_username" {
  description = "Snowflake username used by Terraform (needs ACCOUNTADMIN)"
  type        = string
}

variable "snowflake_password" {
  description = "Snowflake password for the Terraform admin user"
  type        = string
  sensitive   = true
}

variable "snowflake_dbt_password" {
  description = "Password for DBT_USER"
  type        = string
  sensitive   = true
}

variable "snowflake_tableau_password" {
  description = "Password for TABLEAU_USER"
  type        = string
  sensitive   = true
}

// **********************************