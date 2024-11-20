# Lab 1 - Deploying a Container App to Azure with Bicep

This lab demonstrates deploying a simple Container App to Azure using Bicep and automating the deployment with GitHub Actions. The Bicep file uses a declarative syntax to define Azure resources, allowing for consistent, repeatable deployments while treating your infrastructure as code.

## Contents

- **lab.bicep** A Bicep file that declares a Container App in Azure.
- **load.js**: K6 script for load testing the containerApp.

### 


### Accessing the Application


## File Structure
```bash
.
├── application.bicep        # Bicep file that declares a Container App in Azure
├── ../.github/workflows/
│       └── lab3-bicep-deploy.yml

