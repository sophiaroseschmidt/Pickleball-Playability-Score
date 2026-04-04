# Random suffix for unique names
resource "random_id" "suffix" {
  byte_length = 4
}

// Azure Resources
// **********************************

# Resource Group
data "azurerm_resource_group" "main" {
  name = var.resource_group
}

# Key Vault for secrets
resource "azurerm_key_vault" "main" {
  name                       = "kv-pickleball-${random_id.suffix.hex}"
  location                   = data.azurerm_resource_group.main.location
  resource_group_name        = data.azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  tags = var.tags
}

# Get current Azure client config
data "azurerm_client_config" "current" {}

# Key Vault access policy for current user
resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Purge", "Recover"
  ]
}

resource "azurerm_consumption_budget_resource_group" "alerts" {
  name              = "pickleball-budget"
  resource_group_id = data.azurerm_resource_group.main.id

  amount     = 10
  time_grain = "Monthly"

  time_period {
    start_date = "2026-03-01T00:00:00Z"
    end_date   = "2027-03-01T00:00:00Z"
  }

  notification {
    enabled        = true
    threshold      = 30
    operator       = "GreaterThan"
    contact_emails = [var.budget_alert_email]
  }
}

// KEYVAULT SECRETS ---------------------------

# Store Snowflake credentials in Key Vault
resource "azurerm_key_vault_secret" "snowflake_account" {
  name         = "snowflake-account"
  value        =  "${var.snowflake_organization}-${var.snowflake_account_name}"
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault_access_policy.current_user]
}

resource "azurerm_key_vault_secret" "snowflake_dbt_password" {
  name         = "snowflake-dbt-password"
  value        = var.snowflake_dbt_password
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault_access_policy.current_user]
}

resource "azurerm_key_vault_secret" "snowflake_tableau_password" {
  name         = "snowflake-tableau-password"
  value        = var.snowflake_tableau_password
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault_access_policy.current_user]
}

# Convenience connection string for the Python pipelines
resource "azurerm_key_vault_secret" "snowflake_dbt_connection" {
  name         = "snowflake-dbt-connection"
  value        = "snowflake://DBT_USER:${var.snowflake_dbt_password}@${var.snowflake_organization}-${var.snowflake_account_name}/PICKLEBALL_DB?warehouse=PICKLEBALL_WH"
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault_access_policy.current_user]
}

// **********************************
