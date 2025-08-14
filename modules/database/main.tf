# Random password for admin user
resource "random_password" "admin" {
  length  = 32
  special = true
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                = "psql-${var.environment}-${random_string.suffix.result}"
  resource_group_name = var.resource_group_name
  location           = var.location
  version            = "16"
  
  administrator_login    = var.admin_username
  administrator_password = random_password.admin.result
  
  authentication {
    active_directory_auth_enabled = true
    password_auth_enabled         = true
    tenant_id                    = data.azurerm_client_config.current.tenant_id
  }
  
  sku_name   = var.sku_name
  storage_mb = var.storage_mb
  zone       = "1"
  
  backup_retention_days         = 35
  geo_redundant_backup_enabled = true
  
  high_availability {
    mode                      = "ZoneRedundant"
    standby_availability_zone = "2"
  }
  
  delegated_subnet_id = var.delegated_subnet_id
  private_dns_zone_id = var.private_dns_zone_id
  
  tags = var.tags
  
  depends_on = [var.private_dns_zone_id]
}

# Database creation
resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = "app_database"
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# PostgreSQL configurations for performance
resource "azurerm_postgresql_flexible_server_configuration" "max_connections" {
  name      = "max_connections"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "800"
}

resource "azurerm_postgresql_flexible_server_configuration" "shared_buffers" {
  name      = "shared_buffers"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "8GB"
}

resource "azurerm_postgresql_flexible_server_configuration" "ssl_enforcement" {
  name      = "ssl"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "on"
}

# Diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "postgresql" {
  name               = "postgresql-diagnostics"
  target_resource_id = azurerm_postgresql_flexible_server.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "PostgreSQLLogs"
  }
  
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Alerts
resource "azurerm_monitor_action_group" "database_alerts" {
  name                = "database-alerts-${var.environment}"
  resource_group_name = var.resource_group_name
  short_name          = "dbealerts"

  email_receiver {
    name          = "database-team"
    email_address = "alerts@company.com"
  }
}

resource "azurerm_monitor_metric_alert" "cpu_alert" {
  name                = "postgresql-cpu-alert-${var.environment}"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_postgresql_flexible_server.main.id]
  
  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }
  
  frequency   = "PT1M"
  window_size = "PT5M"
  severity    = 2
  
  action {
    action_group_id = azurerm_monitor_action_group.database_alerts.id
  }
}

resource "azurerm_monitor_metric_alert" "storage_alert" {
  name                = "postgresql-storage-alert-${var.environment}"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_postgresql_flexible_server.main.id]
  
  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "storage_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }
  
  frequency   = "PT1M"
  window_size = "PT5M"
  severity    = 1
  
  action {
    action_group_id = azurerm_monitor_action_group.database_alerts.id
  }
}

# Data sources
data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}