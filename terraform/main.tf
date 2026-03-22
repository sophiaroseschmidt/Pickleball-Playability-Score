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

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.project_name}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
  tags                = var.tags
}

# Subnet for PostgreSQL
resource "azurerm_subnet" "postgres" {
  name                 = "postgres-subnet"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
  
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# Private DNS Zone for PostgreSQL
resource "azurerm_private_dns_zone" "postgres" {
  name                = "${var.project_name}-pdz.postgres.database.azure.com"
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = var.tags
}

# Link DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "pdzvnetlink-${var.project_name}"
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = azurerm_virtual_network.main.id
  resource_group_name   = data.azurerm_resource_group.main.name
  tags                  = var.tags
}

# PostgreSQL Database
resource "azurerm_postgresql_flexible_server_database" "airflow_db" {
  name      = "airflow_db"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# Firewall rule to allow Azure services
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  name             = "allow-azure-services"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Firewall rules for allowed IPs
resource "azurerm_postgresql_flexible_server_firewall_rule" "allowed_ips" {
  count            = length(var.allowed_ip_addresses)
  name             = "allowed-ip-${count.index}"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = var.allowed_ip_addresses[count.index]
  end_ip_address   = var.allowed_ip_addresses[count.index]
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

# Store database credentials in Key Vault
resource "azurerm_key_vault_secret" "db_connection_string" {
  name         = "database-connection-string"
  value        = "postgresql://${var.db_admin_username}:${var.db_admin_password}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${azurerm_postgresql_flexible_server_database.airflow_db.name}?sslmode=require"
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault_access_policy.current_user]
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
    contact_emails = var.budget_alert_email
  }
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "${var.project_name}-psql-${random_id.suffix.hex}"
  resource_group_name    = data.azurerm_resource_group.main.name
  location               = data.azurerm_resource_group.main.location
  version                = "15"
  delegated_subnet_id    = azurerm_subnet.postgres.id
  private_dns_zone_id    = azurerm_private_dns_zone.postgres.id
  administrator_login    = var.db_admin_username
  administrator_password = var.db_admin_password
  zone                   = "1"

  storage_mb = 32768  # 32 GB

  sku_name   = "B_Standard_B1ms"  # Basic tier, ~$12/month
  # For production: "GP_Standard_D2s_v3" (~$120/month)

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  tags = var.tags

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}

# KEYVAULT SECRETS ---------------------------

resource "azurerm_key_vault_secret" "db_password" {
  name         = "database-password"
  value        = var.db_admin_password
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault_access_policy.current_user]
}

# Store Snowflake credentials in Key Vault
resource "azurerm_key_vault_secret" "snowflake_account" {
  name         = "snowflake-account"
  value        = var.snowflake_account
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


# Convenience connection strings for the Python pipelines
resource "azurerm_key_vault_secret" "snowflake_dbt_connection" {
  name         = "snowflake-dbt-connection"
  # Tells python how to connect to Snowflake
  value        = "snowflake://DBT_USER:${var.snowflake_dbt_password}@${var.snowflake_account}/PICKLEBALL_DB?warehouse=PICKLEBALL_WH"
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault_access_policy.current_user]
}

// **********************************

