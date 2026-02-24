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

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.raw_data.name
}

output "storage_account_primary_access_key" {
  description = "Primary access key for storage account"
  value       = azurerm_storage_account.raw_data.primary_access_key
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