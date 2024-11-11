# Lab 1 - Deploying a Container App to Azure with Bicep

This lab demonstrates deploying a simple Container App to Azure using Bicep and automating the deployment with GitHub Actions. The Bicep file uses a declarative syntax to define Azure resources, allowing for consistent, repeatable deployments while treating your infrastructure as code.

## Contents

- **application.bicep** A Bicep file that declares a Container App in Azure.
- **GitHub Workflow** An automated deployment workflow using GitHub Actions.

## Getting Started

### Prerequisites
1. **Azure Subscription**: Ensure you have an active Azure subscription.
2. **Azure CLI**: Install the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) and log in using `az login`.
3. **GitHub Account**: Have a GitHub account with permissions to create repositories and secrets.
4. **GitHub Secrets**: Add the following secrets to your GitHub repository:
   - **`AZURE_SUBSCRIPTION_ID`**: Your Azure subscription ID.
   - **`AZURE_RESOURCE_GROUP`**: The name of the resource group for the deployment.
   - **`AZURE_CREDENTIALS`**: A JSON object with your Azure service principal credentials.

### Setup

1. **Clone the Repository**: Clone your GitHub repository to your local machine.
   ```bash
   git clone <repository-url>
   cd <repository-name>
	


      
This command maps port 8080 on your host machine to port 80 in the container, where Nginx is listening and serving the content in the html directory.

### Accessing the Application


## File Structure
```bash
.
├── application.bicep        # Bicep file that declares a Container App in Azure
├── .github/
│   └── workflows/
│       └── deploy.yml

