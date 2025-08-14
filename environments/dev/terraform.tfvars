environment                    = "dev"
location                      = "Australia East"
resource_group_name           = "acme-pets-terraform-state"
container_app_environment_name = "acmepets-container-app-env-dev"
app1_name                     = "acmepets-simple-frontend-dev"
app2_name                     = "acmepets-simple-paging-system-dev"
app1_image                    = "acracmepets.azurecr.io/acmepets-simple-frontend:latest"
app2_image                    = "acracmepets.azurecr.io/acmepets-simple-paging-system:latest"
app1_port                     = 3000
app2_port                     = 3001
key_vault_name                = "kv-nodeapp-dev-001"
postgres_server_name          = "postgres-flexible-acme-dev"
postgres_database_name        = "nodeapp_dev"
postgres_admin_username       = "postgresadmin"
postgres_admin_password       = ""  # Will be auto-generated if empty
postgres_sku_name            = "B_Standard_B1ms"
postgres_storage_mb          = 32768
postgres_version             = "15"
min_replicas                 = 2
max_replicas                 = 5
node_env                     = "development"

tags = {
  Environment = "dev"
  Project     = "nodejs-containerapp"
  ManagedBy   = "terraform"
  Stack       = "nodejs-postgresql"
}