environment                    = "prod"
location                       = "Australia East"
resource_group_name            = "rg-nodeapp-prod-australiaeast"
container_app_environment_name = "cae-nodeapp-prod-australiaeast"
app1_name                      = "nodeapp1-prod"
app2_name                      = "nodeapp2-prod"
app1_image                     = "your-registry.azurecr.io/nodeapp1:latest"
app2_image                     = "your-registry.azurecr.io/nodeapp2:latest"
app1_port                      = 3000
app2_port                      = 3001
key_vault_name                 = "kv-nodeapp-prod-001"
postgres_server_name           = "postgres-nodeapp-prod-001"
postgres_database_name         = "nodeapp_prod"
postgres_admin_username        = "postgresadmin"
postgres_admin_password        = "" # Set via environment variable or GitHub secret
postgres_sku_name              = "GP_Standard_D2s_v3"
postgres_storage_mb            = 131072
postgres_version               = "15"
min_replicas                   = 3
max_replicas                   = 20
node_env                       = "production"

tags = {
  Environment = "prod"
  Project     = "nodejs-containerapp"
  ManagedBy   = "terraform"
  Stack       = "nodejs-postgresql"
}