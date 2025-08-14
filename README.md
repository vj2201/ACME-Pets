# ACME Pets - Azure Container Apps Infrastructure

This repository contains the complete Infrastructure as Code (IaC) solution for deploying the ACME Pets application on Azure Container Apps with PostgreSQL backend using a **modular, multi-environment approach**.

## 🏗️ Architecture

**Multi-Environment Deployment via Parameters** - Single Terraform module deploys to dev, test, and prod environments by passing parameters.

```
modules/acme-pets/          # Reusable module
├── main.tf                 # Core infrastructure
├── variables.tf            # Parameters for customization
└── outputs.tf              # Environment outputs

environments/
├── dev/main.tf             # Dev environment (uses module)
├── test/main.tf            # Test environment (uses module)  
└── prod/main.tf            # Prod environment (uses module)
```

## 🚀 Quick Start

### 1. Setup
```bash
# Clone and setup
git clone <your-repo-url>
cd acme-pets-infrastructure
chmod +x scripts/setup.sh
./scripts/setup.sh
```

### 2. Deploy Environments
```bash
# Deploy development
cd environments/dev && terraform init && terraform apply

# Deploy test  
cd ../test && terraform init && terraform apply

# Deploy production
cd ../prod && terraform init && terraform apply
```

## 📋 Environment Configuration

| Environment | Replicas | Database SKU | Network | Retention |
|-------------|----------|--------------|---------|-----------|
| **dev** | 1-3 | B_Standard_B1ms | 10.10.0.0/16 | 7 days |
| **test** | 1-5 | GP_Standard_D2s_v3 | 10.20.0.0/16 | 30 days |
| **prod** | 2-15 | GP_Standard_D4s_v3 | 10.0.0.0/16 | 90 days |

## 🔄 CI/CD Pipeline

GitHub Actions automatically deploys based on branch:
- `main` branch → Production environment
- `develop` branch → Test environment  
- `feature/*` → Development validation

Manual deployment via workflow dispatch with environment parameter selection.

## 📚 Documentation

- [Complete Deployment Guide](docs/deployment-guide.md)
- [Observability Plan](docs/observability-plan.md)
- [Multi-Environment Setup](examples/terraform.tfvars.examples)

## 🏆 Features

✅ **Parameter-driven multi-environment deployment**  
✅ **Terraform modules for code reusability**  
✅ **Environment-specific resource sizing**  
✅ **Complete CI/CD pipeline**  
✅ **Comprehensive monitoring and alerting**  
✅ **Enterprise security (Key Vault, Managed Identity)**  
✅ **Auto-scaling for 1,000+ concurrent users**  

## 🤝 Contributing

1. Create feature branch from `develop`
2. Make changes and test in dev environment
3. Create pull request with detailed description
4. Deploy to test via `develop` branch
5. Promote to production via `main` branch

---

**Maintained by**: ACME Pets Platform Team  
**License**: MIT
