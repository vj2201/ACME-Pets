variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "Australia East"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "rg-nodeapp-prod-australiaeast"
}

variable "container_app_environment_name" {
  description = "Container App Environment name"
  type        = string
  default     = "cae-nodeapp-prod-australiaeast"
}

variable "app1_name" {
  description = "First Node.js container app name"
  type        = string
  default     = "nodeapp1-prod"
}

variable "app2_name" {
  description = "Second Node.js container app name"
  type        = string
  default     = "nodeapp2-prod"
}

variable "app1_image" {
  description = "First Node.js container image"
  type        = string
  default     = "your-registry.azurecr.io/nodeapp1:latest"
}

variable "app2_image" {
  description = "Second Node.js container image"
  type        = string
  default     = "your-registry.azurecr.io/nodeapp2:latest"
}

variable "app1_port" {
  description = "First Node.js app port"
  type        = number
  default     = 3000
}

variable "app2_port" {
  description = "Second Node.js app port"
  type        = number
  default     = 3001
}

variable "key_vault_name" {
  description = "Azure Key Vault name"
  type        = string
  default     = "kv-nodeapp-prod-001"
}

variable "postgres_server_name" {
  description = "PostgreSQL flexible server name"
  type        = string
  default     = "postgres-nodeapp-prod-001"
}

variable "postgres_database_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "nodeapp_prod"
}

variable "postgres_admin_username" {
  description = "PostgreSQL admin username"
  type        = string
  default     = "postgresadmin"
}

variable "postgres_admin_password" {
  description = "PostgreSQL admin password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "postgres_sku_name" {
  description = "PostgreSQL SKU name"
  type        = string
  default     = "GP_Standard_D2s_v3"
}

variable "postgres_storage_mb" {
  description = "PostgreSQL storage in MB"
  type        = number
  default     = 131072
}

variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15"
}

variable "min_replicas" {
  description = "Minimum number of replicas"
  type        = number
  default     = 3
}

variable "max_replicas" {
  description = "Maximum number of replicas"
  type        = number
  default     = 20
}

variable "node_env" {
  description = "Node.js environment"
  type        = string
  default     = "production"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "prod"
    Project     = "nodejs-containerapp"
    ManagedBy   = "terraform"
    Stack       = "nodejs-postgresql"
  }
}