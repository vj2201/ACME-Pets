output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "container_app_environment_id" {
  description = "ID of the Container App Environment"
  value       = azurerm_container_app_environment.main.id
}

output "app1_fqdn" {
  description = "FQDN of the first Node.js container app"
  value       = azurerm_container_app.app1.latest_revision_fqdn
}

output "app2_fqdn" {
  description = "FQDN of the second Node.js container app"
  value       = azurerm_container_app.app2.latest_revision_fqdn
}

output "postgres_server_fqdn" {
  description = "FQDN of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "postgres_database_name" {
  description = "PostgreSQL database name"
  value       = azurerm_postgresql_flexible_server_database.main.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = var.key_vault_name != "" ? azurerm_key_vault.main[0].vault_uri : null
}

output "database_connection_string" {
  description = "PostgreSQL connection string (sensitive)"
  value       = "postgresql://${var.postgres_admin_username}:${local.postgres_password}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${var.postgres_database_name}?sslmode=require"
  sensitive   = true
}