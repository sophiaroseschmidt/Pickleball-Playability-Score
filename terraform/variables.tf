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


// Snowflake
// **********************************

variable "snowflake_organization" {
  description = "Snowflake organization name"
  type        = string
}

variable "snowflake_account_name" {
  description = "Snowflake account name (without org prefix)"
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