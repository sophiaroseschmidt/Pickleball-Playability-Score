terraform {
  required_version = ">= 1.0"

  backend "azurerm" {
    # Connection details supplied via backend.tfbackend at init time:
    # terraform init -backend-config=backend.tfbackend
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.94"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "snowflake" {
  account  = var.snowflake_account  # format: orgname-accountname
  username = var.snowflake_username
  password = var.snowflake_password
  role     = "ACCOUNTADMIN"         # needs ACCOUNTADMIN to manage roles and users
}
