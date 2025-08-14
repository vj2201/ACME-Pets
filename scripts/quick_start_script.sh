#!/bin/bash

# ACME Pets Quick Start Deployment Script
# This script helps set up the initial Azure infrastructure for Terraform state management

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="acme-pets"
RESOURCE_GROUP="${PROJECT_NAME}-terraform-state"
LOCATION="East US"
ENVIRONMENTS=("dev" "test" "prod")

echo -e "${BLUE}🚀 ACME Pets Infrastructure Setup${NC}"
echo "=================================="

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI is not installed. Please install it first.${NC}"
    exit 1
fi

if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform is not installed. Please install it first.${NC}"
    exit 1
fi

if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ Git is not installed. Please install it first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"

# Login to Azure
echo -e "${YELLOW}🔐 Checking Azure login status...${NC}"
if ! az account show &> /dev/null; then
    echo "Please login to Azure:"
    az login
fi

# Get subscription details
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
echo -e "${GREEN}✅ Using subscription: ${SUBSCRIPTION_ID}${NC}"

# Create service principal
echo -e "${YELLOW}👤 Creating service principal for Terraform...${NC}"
SP_NAME="${PROJECT_NAME}-terraform-sp"

# Check if service principal already exists
if az ad sp list --display-name "$SP_NAME" --query "[0].appId" -o tsv | grep -q .; then
    echo -e "${YELLOW}⚠️  Service principal already exists. Retrieving details...${NC}"
    APP_ID=$(az ad sp list --display-name "$SP_NAME" --query "[0].appId" -o tsv)
    echo -e "${BLUE}App ID: ${APP_ID}${NC}"
    echo -e "${YELLOW}⚠️  You'll need to create a new client secret in Azure Portal${NC}"
else
    echo "Creating new service principal..."
    SP_OUTPUT=$(az ad sp create-for-rbac --name "$SP_NAME" \
        --role="Contributor" \
        --scopes="/subscriptions/$SUBSCRIPTION_ID" \
        --output json)
    
    APP_ID=$(echo $SP_OUTPUT | jq -r '.appId')
    CLIENT_SECRET=$(echo $SP_OUTPUT | jq -r '.password')
    
    echo -e "${GREEN}✅ Service principal created successfully${NC}"
    echo -e "${BLUE}App ID: ${APP_ID}${NC}"
    echo -e "${BLUE}Client Secret: ${CLIENT_SECRET}${NC}"
fi

# Create resource group for Terraform state
echo -e "${YELLOW}📦 Creating resource group for Terraform state...${NC}"
if az group show --name "$RESOURCE_GROUP" &> /dev/null; then
    echo -e "${YELLOW}⚠️  Resource group already exists${NC}"
else
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
    echo -e "${GREEN}✅ Resource group created: ${RESOURCE_GROUP}${NC}"
fi

# Create storage accounts for each environment
echo -e "${YELLOW}💾 Creating storage accounts for Terraform state...${NC}"
declare -A STORAGE_KEYS

for ENV in "${ENVIRONMENTS[@]}"; do
    STORAGE_ACCOUNT="${PROJECT_NAME//[-_]/}terraform${ENV}"
    
    echo "Setting up storage for environment: $ENV"
    
    # Create storage account
    if az storage account show --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
        echo -e "${YELLOW}⚠️  Storage account $STORAGE_ACCOUNT already exists${NC}"
    else
        az storage account create \
            --name "$STORAGE_ACCOUNT" \
            --resource-group "$RESOURCE_GROUP" \
            --location "$LOCATION" \
            --sku Standard_LRS \
            --encryption-services blob \
            --https-only true \
            --min-tls-version TLS1_2
        echo -e "${GREEN}✅ Storage account created: ${STORAGE_ACCOUNT}${NC}"
    fi
    
    # Create container
    ACCESS_KEY=$(az storage account keys list \
        --resource-group "$RESOURCE_GROUP" \
        --account-name "$STORAGE_ACCOUNT" \
        --query '[0].value' -o tsv)
    
    az storage container create \
        --name terraform-state \
        --account-name "$STORAGE_ACCOUNT" \
        --account-key "$ACCESS_KEY" \
        --public-access off
    
    STORAGE_KEYS[$ENV]=$ACCESS_KEY
    echo -e "${GREEN}✅ Container created for ${ENV} environment${NC}"
done

# Create project structure
echo -e "${YELLOW}📁 Creating project structure...${NC}"
PROJECT_DIR="${PROJECT_NAME}-infrastructure"

if [ -d "$PROJECT_DIR" ]; then
    echo -e "${YELLOW}⚠️  Directory $PROJECT_DIR already exists${NC}"
    read -p "Do you want to continue? This might overwrite files. (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
else
    mkdir "$PROJECT_DIR"
fi

cd "$PROJECT_DIR"

# Create directory structure
mkdir -p modules/{networking,database,container-apps,monitoring}
mkdir -p environments/{dev,test,prod}
mkdir -p .github/workflows

echo -e "${GREEN}✅ Project structure created${NC}"

# Generate GitHub secrets instructions
echo -e "${YELLOW}🔧 Generating GitHub secrets configuration...${NC}"

cat > github-secrets-setup.md << EOF
# GitHub Secrets Configuration

Add the following secrets to your GitHub repository:
Settings → Secrets and variables → Actions → New repository secret

## Azure Authentication
- ARM_CLIENT_ID: ${APP_ID}
- ARM_CLIENT_SECRET: ${CLIENT_SECRET:-"<Generate new secret in Azure Portal>"}
- ARM_SUBSCRIPTION_ID: ${SUBSCRIPTION_ID}
- ARM_TENANT_ID: ${TENANT_ID}

## Container Registry (Update with your ACR details)
- ACR_PASSWORD: <your-acr-password>

## Storage Account Access Keys
EOF

for ENV in "${ENVIRONMENTS[@]}"; do
    STORAGE_ACCOUNT="${PROJECT_NAME//[-_]/}terraform${ENV}"
    cat >> github-secrets-setup.md << EOF
- ARM_ACCESS_KEY_${ENV^^}: ${STORAGE_KEYS[$ENV]}
- STORAGE_ACCOUNT_${ENV^^}: ${STORAGE_ACCOUNT}
- CONTAINER_NAME_${ENV^^}: terraform-state
EOF
done

cat >> github-secrets-setup.md << EOF

## Optional (for cost estimation)
- INFRACOST_API_KEY: <get from infracost.io>

## Required Variables to Update
Before deploying, update these files with your actual values:

EOF

for ENV in "${ENVIRONMENTS[@]}"; do
    cat >> github-secrets-setup.md << EOF
### environments/${ENV}/terraform.tfvars
- acr_server: "your-acr-name.azurecr.io"
- acr_username: "your-acr-username"
- web_app_image: "your-image-name"
- alert_email: "your-email@acmepets.com"

EOF
done

echo -e "${GREEN}✅ GitHub secrets configuration saved to github-secrets-setup.md${NC}"

# Generate local testing script
cat > local-deploy.sh << 'EOF'
#!/bin/bash

# Local deployment script for testing
# Usage: ./local-deploy.sh <environment> <acr-password>

ENV=${1:-dev}
ACR_PASSWORD=${2}

if [ -z "$ACR_PASSWORD" ]; then
    echo "Usage: $0 <environment> <acr-password>"
    echo "Example: $0 dev myacrpassword123"
    exit 1
fi

echo "Deploying to $ENV environment..."

cd "environments/$ENV"

# Export ACR password
export TF_VAR_acr_password="$ACR_PASSWORD"

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Plan deployment
echo "Planning deployment..."
terraform plan -out=tfplan

# Ask for confirmation
read -p "Apply this plan? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    terraform apply tfplan
    echo "Deployment completed!"
    echo "Check outputs:"
    terraform output
else
    echo "Deployment cancelled."
fi
EOF

chmod +x local-deploy.sh
echo -e "${GREEN}✅ Local deployment script created${NC}"

# Generate README
cat > README.md << EOF
# ACME Pets Infrastructure

This repository contains the Terraform infrastructure code for deploying ACME Pets application on Azure Container Apps.

## Quick Start

1. **Set up GitHub secrets** using the configuration in \`github-secrets-setup.md\`
2. **Update configuration files** in each environment directory with your actual ACR details
3. **Push to GitHub** - CI/CD pipeline will handle deployment

## Local Testing

For local testing, use the provided script:
\`\`\`bash
./local-deploy.sh dev your-acr-password
\`\`\`

## Environment Structure

- \`environments/dev/\` - Development environment
- \`environments/test/\` - Testing environment  
- \`environments/prod/\` - Production environment

## Modules

- \`modules/networking/\` - VNet, subnets, DNS
- \`modules/database/\` - PostgreSQL Flexible Server
- \`modules/container-apps/\` - Azure Container Apps
- \`modules/monitoring/\` - Application Insights, alerts

## Deployment Pipeline

- **Pull Request**: Plan and security scan
- **Merge to develop**: Deploy to dev
- **Merge to main**: Deploy to test and prod (with approval)

For detailed instructions, see the deployment guide artifacts.
EOF

echo -e "${GREEN}✅ README.md created${NC}"

# Summary
echo
echo -e "${GREEN}🎉 Setup completed successfully!${NC}"
echo "=================================="
echo -e "${BLUE}📁 Project directory: ${PROJECT_DIR}${NC}"
echo -e "${BLUE}📋 Next steps:${NC}"
echo "1. Copy the Terraform module files from the provided artifacts"
echo "2. Set up GitHub secrets using github-secrets-setup.md"
echo "3. Update terraform.tfvars files with your ACR details"
echo "4. Push to GitHub repository"
echo "5. Set up GitHub environments (dev, test, prod) with protection rules"
echo
echo -e "${YELLOW}⚠️  Important files created:${NC}"
echo "- github-secrets-setup.md (GitHub secrets configuration)"
echo "- local-deploy.sh (Local testing script)"
echo "- README.md (Project documentation)"
echo
echo -e "${BLUE}💡 For local testing:${NC}"
echo "./local-deploy.sh dev your-acr-password"
echo
echo -e "${GREEN}Happy deploying! 🚀${NC}"