output "app1_url" {
  description = "URL of the first Node.js container app"
  value       = "https://${module.container_apps.app1_fqdn}"
}

output "app2_url" {
  description = "URL of the second Node.js container app"
  value       = "https://${module.container_apps.app2_fqdn}"
}

output "postgres_server_fqdn" {
  description = "PostgreSQL server FQDN"
  value       = module.container_apps.postgres_server_fqdn
}

output "postgres_database_name" {
  description = "PostgreSQL database name"
  value       = module.container_apps.postgres_database_name
}

output "resource_group_name" {
  description = "Resource group name"
  value       = module.container_apps.resource_group_name
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = module.container_apps.key_vault_uri
}