terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  # Backend should be here, not in module block
  backend "azurerm" {
    resource_group_name  = "acme-pets-terraform-state"
    storage_account_name = "acmepetsterraformdev"
    container_name       = "terraform-state"
    key                  = "dev/container-apps.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
  skip_provider_registration = true
}

# Single module block with all variables
module "container_apps" {
  source = "../../modules/container-apps"

  environment                    = var.environment
  location                       = var.location
  resource_group_name            = var.resource_group_name
  container_app_environment_name = var.container_app_environment_name
  app1_name                      = var.app1_name
  app2_name                      = var.app2_name
  app1_image                     = var.app1_image
  app2_image                     = var.app2_image
  app1_port                      = var.app1_port
  app2_port                      = var.app2_port
  key_vault_name                 = var.key_vault_name
  postgres_server_name           = var.postgres_server_name
  postgres_database_name         = var.postgres_database_name
  postgres_admin_username        = var.postgres_admin_username
  postgres_admin_password        = var.postgres_admin_password
  postgres_sku_name              = var.postgres_sku_name
  postgres_storage_mb            = var.postgres_storage_mb
  postgres_version               = var.postgres_version
  min_replicas                   = var.min_replicas
  max_replicas                   = var.max_replicas
  node_env                       = var.node_env
  tags                           = var.tags

  # ACR authentication variables
  acr_server   = var.acr_server
  acr_username = var.acr_username
  acr_password = var.acr_password
  acr_server   = var.acr_server
  acr_username = var.acr_username
  acr_password = var.acr_password
}