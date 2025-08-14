# Variables
RESOURCE_GROUP="acme-pets-terraform-state"
LOCATION="australiaeast"

# Create resource group
az group create --name $RESOURCE_GROUP --location "$LOCATION"

# Create storage accounts for each environment
for ENV in dev test prod; do
  STORAGE_ACCOUNT="acmepetsterraform${ENV}"
  
  az storage account create \
    --name $STORAGE_ACCOUNT \
    --resource-group $RESOURCE_GROUP \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --encryption-services blob
  
  # Create container
  az storage container create \
    --name terraform-state \
    --account-name $STORAGE_ACCOUNT
  
  # Get access key
  az storage account keys list \
    --resource-group $RESOURCE_GROUP \
    --account-name $STORAGE_ACCOUNT \
    --query '[0].value' -o tsv
done