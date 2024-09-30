
# Azure Bicep Deployment Workflow

## Environment Setup

Before running the deployment workflows, you need to configure the following **GitHub Secrets**:

- **`AZURE_SUBSCRIPTION_ID`**: This should point to an active Azure subscription.
- **`AZURE_RESOURCE_GROUP`**: The name of the resource group. If it does not exist, it will be created automatically.

### Steps to Configure Secrets

1. Go to your repository's **Settings**.
2. Navigate to **Secrets and variables** > **Actions**.
3. Add the following secrets:
   - `AZURE_SUBSCRIPTION_ID`: Your Azure subscription ID.
   - `AZURE_RESOURCE_GROUP`: The name of the resource group.

## Triggering the Infrastructure Setup

Once the secrets are configured, you can set up the infrastructure by triggering the GitHub Actions workflow named **`azure-bicep-deploy`**.

This will:
- Create or update the specified resource group (if it doesn't exist).
- Deploy the infrastructure using a Bicep template to the specified resource group.
  
> **Note:** The resource group will be created in the **`swedencentral`** region by default.

## Deploying the Test WebApp

To deploy the test web application, you can either:

1. **Push a change** to the repository (e.g., update code or configuration).
2. Manually **trigger** the GitHub Actions workflow named **`webapp-workflow`**.

This will build and deploy the web application to the Azure environment set up in the resource group.

## Tearing Down the Environment

To tear down and remove all resources in the resource group, run the following command:

```bash
az group delete --name <AZURE_RESOURCE_GROUP> --subscription <AZURE_SUBSCRIPTION_ID> --yes --no-wait
```

This will delete the resource group and all associated resources in Azure.
