variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "Australia East"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "rg-nodeapp-dev-australiaeast"
}

variable "container_app_environment_name" {
  description = "Container App Environment name"
  type        = string
  default     = "cae-nodeapp-dev-australiaeast"
}

variable "app1_name" {
  description = "First Node.js container app name"
  type        = string
  default     = "nodeapp1-dev"
}

variable "app2_name" {
  description = "Second Node.js container app name"
  type        = string
  default     = "nodeapp2-dev"
}

variable "app1_image" {
  description = "First Node.js container image"
  type        = string
  default     = "node:18-alpine"
}

variable "app2_image" {
  description = "Second Node.js container image"
  type        = string
  default     = "node:18-alpine"
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
  default     = "kv-nodeapp-dev-001"
}

variable "postgres_server_name" {
  description = "PostgreSQL flexible server name"
  type        = string
  default     = "postgres-nodeapp-dev-001"
}

variable "postgres_database_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "nodeapp_dev"
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
  default     = "B_Standard_B1ms"
}

variable "postgres_storage_mb" {
  description = "PostgreSQL storage in MB"
  type        = number
  default     = 32768
}

variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15"
}

variable "min_replicas" {
  description = "Minimum number of replicas"
  type        = number
  default     = 2
}

variable "max_replicas" {
  description = "Maximum number of replicas"
  type        = number
  default     = 5
}

variable "node_env" {
  description = "Node.js environment"
  type        = string
  default     = "development"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "nodejs-containerapp"
    ManagedBy   = "terraform"
    Stack       = "nodejs-postgresql"
  }
}
variable "acr_server" {
  description = "ACR server URL"
  type        = string
  default     = "acracmepets.azurecr.io"
}

variable "acr_username" {
  description = "ACR username"
  type        = string
  sensitive   = true
}

variable "acr_password" {
  description = "ACR password"
  type        = string
  sensitive   = true
}