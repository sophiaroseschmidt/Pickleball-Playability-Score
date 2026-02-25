output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "postgresql_fqdn" {
  description = "Fully qualified domain name of PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "postgresql_database_name" {
  description = "Name of the PostgreSQL database"
  value       = azurerm_postgresql_flexible_server_database.finance_db.name
}

output "connection_string" {
  description = "PostgreSQL connection string"
  value       = "postgresql://${var.db_admin_username}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${azurerm_postgresql_flexible_server_database.finance_db.name}?sslmode=require"
  sensitive   = true
}


output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

# ─── Snowflake ─────────────────────────────────────────────────────────────────

output "snowflake_database" {
  description = "Snowflake database name"
  value       = snowflake_database.pickleball.name
}

output "snowflake_warehouse" {
  description = "Snowflake warehouse name"
  value       = snowflake_warehouse.main.name
}

output "snowflake_dbt_user" {
  description = "Snowflake username for dbt"
  value       = snowflake_user.dbt.name
}

output "snowflake_tableau_user" {
  description = "Snowflake username for Tableau"
  value       = snowflake_user.tableau.name
}