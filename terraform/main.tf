// Azure Resources
// **********************************

# Random suffix for unique names
resource "random_id" "suffix" {
  byte_length = 4
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
  tags     = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.project_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
  tags                = var.tags
}

# Subnet for PostgreSQL
resource "azurerm_subnet" "postgres" {
  name                 = "postgres-subnet"
  resource_group_name  = azurerm_resource_group.main.name
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
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# Link DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "pdzvnetlink-${var.project_name}"
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = azurerm_virtual_network.main.id
  resource_group_name   = azurerm_resource_group.main.name
  tags                  = var.tags
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "psql-${var.project_name}-${random_id.suffix.hex}"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
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
  name                       = "kv-${var.project_name}-${random_id.suffix.hex}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
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
  value        = "postgresql://${var.db_admin_username}:${var.db_admin_password}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/finance_db?sslmode=require"
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault_access_policy.current_user]
}

resource "azurerm_key_vault_secret" "db_password" {
  name         = "database-password"
  value        = var.db_admin_password
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault_access_policy.current_user]
}

resource "azurerm_consumption_budget_resource_group" "example" {
name = "example-budget"
resource_group_name = azurerm_resource_group.example.name
amount = 25
time_grain = "Monthly"
start_date = "2023-01-01"
end_date = "2023-12-31"
notifications {
enabled = true
operator = "GreaterThan"
threshold = 90
contact_emails = ["example@example.com"]
}
}

// **********************************

// Snowflake Resources
// **********************************

resource "snowflake_database" "pickleball" {
  name    = "PICKLEBALL_DB"
  comment = "Pickleball Playability Score data warehouse"
}

resource "snowflake_schema" "bronze" {
  database = snowflake_database.pickleball.name
  name     = "BRONZE"
  comment  = "Raw ingested data"
}

resource "snowflake_schema" "silver" {
  database = snowflake_database.pickleball.name
  name     = "SILVER"
  comment  = "Cleaned and conformed data"
}

resource "snowflake_schema" "gold" {
  database = snowflake_database.pickleball.name
  name     = "GOLD"
  comment  = "Ready, aggregated data"
}

resource "snowflake_warehouse" "main" {
  name           = "PICKLEBALL_WH"
  warehouse_size = "XSMALL"
  auto_suspend   = 60   # suspend after 60s of inactivity
  auto_resume    = true
  comment        = "Primary compute warehouse"
}

# SNOWFLAKE ROLES ---------------------------

resource "snowflake_role" "dbt" {
  name    = "DBT_ROLE"
  comment = "Role for dbt transformations — write access to all schemas"
}

resource "snowflake_role" "tableau" {
  name    = "TABLEAU_ROLE"
  comment = "Role for Tableau — read-only access to the gold schema"
}

# SNOWFLAKE USERS ---------------------------

resource "snowflake_user" "dbt" {
  name                 = "DBT_USER"
  password             = var.snowflake_dbt_password
  default_role         = snowflake_role.dbt.name
  default_warehouse    = snowflake_warehouse.main.name
  default_namespace    = "${snowflake_database.pickleball.name}.${snowflake_schema.silver.name}"
  must_change_password = false
  comment              = "Service account for dbt"
}

resource "snowflake_user" "tableau" {
  name                 = "TABLEAU_USER"
  password             = var.snowflake_tableau_password
  default_role         = snowflake_role.tableau.name
  default_warehouse    = snowflake_warehouse.main.name
  default_namespace    = "${snowflake_database.pickleball.name}.${snowflake_schema.gold.name}"
  must_change_password = false
  comment              = "Service account for Tableau"
}

resource "snowflake_grant_role" "dbt_user" {
  role_name = snowflake_role.dbt.name
  user_name = snowflake_user.dbt.name
}

resource "snowflake_grant_role" "tableau_user" {
  role_name = snowflake_role.tableau.name
  user_name = snowflake_user.tableau.name
}

resource "snowflake_grant_privileges_to_role" "dbt_warehouse" {
  role_name  = snowflake_role.dbt.name
  privileges = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.main.name
  }
}

resource "snowflake_grant_privileges_to_role" "tableau_warehouse" {
  role_name  = snowflake_role.tableau.name
  privileges = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.main.name
  }
}

resource "snowflake_grant_privileges_to_role" "dbt_database" {
  role_name  = snowflake_role.dbt.name
  privileges = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.pickleball.name
  }
}

resource "snowflake_grant_privileges_to_role" "tableau_database" {
  role_name  = snowflake_role.tableau.name
  privileges = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.pickleball.name
  }
}
# DBT PRIVILEDGES ---------------------------

resource "snowflake_grant_privileges_to_role" "dbt_schema_bronze" {
  role_name  = snowflake_role.dbt.name
  privileges = ["USAGE", "CREATE TABLE", "CREATE VIEW", "CREATE STAGE", "MODIFY"]
  on_schema {
    schema_name = "${snowflake_database.pickleball.name}.${snowflake_schema.bronze.name}"
  }
}

resource "snowflake_grant_privileges_to_role" "dbt_schema_silver" {
  role_name  = snowflake_role.dbt.name
  privileges = ["USAGE", "CREATE TABLE", "CREATE VIEW", "CREATE STAGE", "MODIFY"]
  on_schema {
    schema_name = "${snowflake_database.pickleball.name}.${snowflake_schema.silver.name}"
  }
}

resource "snowflake_grant_privileges_to_role" "dbt_schema_gold" {
  role_name  = snowflake_role.dbt.name
  privileges = ["USAGE", "CREATE TABLE", "CREATE VIEW", "CREATE STAGE", "MODIFY"]
  on_schema {
    schema_name = "${snowflake_database.pickleball.name}.${snowflake_schema.gold.name}"
  }
}

# TABLEAU PERMISSIONS ---------------------------

resource "snowflake_grant_privileges_to_role" "tableau_schema_gold" {
  role_name  = snowflake_role.tableau.name
  privileges = ["USAGE"]
  on_schema {
    schema_name = "${snowflake_database.pickleball.name}.${snowflake_schema.gold.name}"
  }
}

# Future grants so Tableau can read tables/views created by dbt in gold
resource "snowflake_grant_privileges_to_role" "tableau_future_tables" {
  role_name  = snowflake_role.tableau.name
  privileges = ["SELECT"]
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "${snowflake_database.pickleball.name}.${snowflake_schema.gold.name}"
    }
  }
}

resource "snowflake_grant_privileges_to_role" "tableau_future_views" {
  role_name  = snowflake_role.tableau.name
  privileges = ["SELECT"]
  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_schema          = "${snowflake_database.pickleball.name}.${snowflake_schema.gold.name}"
    }
  }
}
