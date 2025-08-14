output "server_fqdn" {
  description = "PostgreSQL server FQDN"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "server_id" {
  description = "PostgreSQL server ID"
  value       = azurerm_postgresql_flexible_server.main.id
}

output "connection_string" {
  description = "PostgreSQL connection string"
  value = format("postgresql://%s:%s@%s:5432/%s?sslmode=require",
    var.admin_username,
    random_password.admin.result,
    azurerm_postgresql_flexible_server.main.fqdn,
    azurerm_postgresql_flexible_server_database.main.name
  )
  sensitive = true
}

output "admin_username" {
  description = "Admin username"
  value       = azurerm_postgresql_flexible_server.main.administrator_login
}

output "database_name" {
  description = "Database name"
  value       = azurerm_postgresql_flexible_server_database.main.name
}