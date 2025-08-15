terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Data source for current client configuration
data "azurerm_client_config" "current" {}

# Generate random password if not provided
resource "random_password" "postgres_password" {
  count   = var.postgres_admin_password == "" ? 1 : 0
  length  = 16
  special = true
}

locals {
  postgres_password = var.postgres_admin_password != "" ? var.postgres_admin_password : random_password.postgres_password[0].result
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Log Analytics Workspace for Container Apps
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.environment}-law"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# Container App Environment
resource "azurerm_container_app_environment" "main" {
  name                       = var.container_app_environment_name
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  tags                       = var.tags
}

# Key Vault for storing database connection strings and secrets
resource "azurerm_key_vault" "main" {
  count               = var.key_vault_name != "" ? 1 : 0
  name                = var.key_vault_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Recover",
      "Backup",
      "Restore"
    ]
  }

  tags = var.tags
}

# Store PostgreSQL connection string in Key Vault
resource "azurerm_key_vault_secret" "postgres_connection_string" {
  count        = var.key_vault_name != "" ? 1 : 0
  name         = "postgres-connection-string"
  value        = "postgresql://${var.postgres_admin_username}:${local.postgres_password}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${var.postgres_database_name}?sslmode=require"
  key_vault_id = azurerm_key_vault.main[0].id
  
  depends_on = [azurerm_postgresql_flexible_server.main]
}

# Store individual PostgreSQL credentials in Key Vault
resource "azurerm_key_vault_secret" "postgres_password" {
  count        = var.key_vault_name != "" ? 1 : 0
  name         = "postgres-admin-password"
  value        = local.postgres_password
  key_vault_id = azurerm_key_vault.main[0].id
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = var.postgres_server_name
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  version                = var.postgres_version
  administrator_login    = var.postgres_admin_username
  administrator_password = local.postgres_password
  zone ="2" # Use zone-redundant configuration for production environments
  storage_mb   = var.postgres_storage_mb
  sku_name     = var.postgres_sku_name
  
  backup_retention_days = 7
  geo_redundant_backup_enabled = false
  
  # high_availability {
  # mode = var.environment == "prod" ? "ZoneRedundant" : "Disabled"
  #}

  tags = var.tags
}

# PostgreSQL Database
resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = var.postgres_database_name
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# PostgreSQL Firewall Rule to allow Container Apps
resource "azurerm_postgresql_flexible_server_firewall_rule" "container_apps" {
  name             = "AllowContainerApps"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# PostgreSQL Firewall Rule for Azure Services
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  name             = "AllowAllWindowsAzureIps"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Container App 1 - Node.js Application
resource "azurerm_container_app" "app1" {
  name                         = var.app1_name
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  tags                         = var.tags

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = "${var.app1_name}-container"
      image  = var.app1_image
      cpu    = "1.0"
      memory = "2Gi"

      # Node.js specific environment variables
      env {
        name  = "NODE_ENV"
        value = var.node_env
      }

      env {
        name  = "PORT"
        value = tostring(var.app1_port)
      }

      env {
        name  = "DATABASE_URL"
        value = "postgresql://${var.postgres_admin_username}:${local.postgres_password}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${var.postgres_database_name}?sslmode=require"
      }

      env {
        name  = "DB_HOST"
        value = azurerm_postgresql_flexible_server.main.fqdn
      }

      env {
        name  = "DB_PORT"
        value = "5432"
      }

      env {
        name  = "DB_NAME"
        value = var.postgres_database_name
      }

      env {
        name  = "DB_USER"
        value = var.postgres_admin_username
      }

      env {
        name        = "DB_PASSWORD"
        secret_name = "db-password"
      }

      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }

      # Simplified health checks compatible with AzureRM provider
      liveness_probe {
        transport = "HTTP"
        port      = var.app1_port
        path      = "/health"
      }

      readiness_probe {
        transport = "HTTP"
        port      = var.app1_port
        path      = "/ready"
      }
    }

    # HTTP scaling rule
    http_scale_rule {
      name                = "http-scaler"
      concurrent_requests = 50
    }
  }

  secret {
    name  = "db-password"
    value = local.postgres_password
  }

  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = var.app1_port

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  depends_on = [
    azurerm_postgresql_flexible_server.main,
    azurerm_postgresql_flexible_server_database.main
  ]
}

# Container App 2 - Node.js Application
resource "azurerm_container_app" "app2" {
  name                         = var.app2_name
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  tags                         = var.tags

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = "${var.app2_name}-container"
      image  = var.app2_image
      cpu    = "1.0"
      memory = "2Gi"

      # Node.js specific environment variables
      env {
        name  = "NODE_ENV"
        value = var.node_env
      }

      env {
        name  = "PORT"
        value = tostring(var.app2_port)
      }

      env {
        name  = "DATABASE_URL"
        value = "postgresql://${var.postgres_admin_username}:${local.postgres_password}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${var.postgres_database_name}?sslmode=require"
      }

      env {
        name  = "DB_HOST"
        value = azurerm_postgresql_flexible_server.main.fqdn
      }

      env {
        name  = "DB_PORT"
        value = "5432"
      }

      env {
        name  = "DB_NAME"
        value = var.postgres_database_name
      }

      env {
        name  = "DB_USER"
        value = var.postgres_admin_username
      }

      env {
        name        = "DB_PASSWORD"
        secret_name = "db-password"
      }

      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }

      # Simplified health checks compatible with AzureRM provider
      liveness_probe {
        transport = "HTTP"
        port      = var.app2_port
        path      = "/health"
      }

      readiness_probe {
        transport = "HTTP"
        port      = var.app2_port
        path      = "/ready"
      }
    }

    # HTTP scaling rule
    http_scale_rule {
      name                = "http-scaler"
      concurrent_requests = 50
    }
  }

  secret {
    name  = "db-password"
    value = local.postgres_password
  }

  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = var.app2_port

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  depends_on = [
    azurerm_postgresql_flexible_server.main,
    azurerm_postgresql_flexible_server_database.main
  ]
}