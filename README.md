# Scaling Cloud: Cloud-Native Applications with Azure & Docker

Welcome to the **Scaling Cloud** course! This repository is your hands-on guide to building, containerizing, and scaling modern web applications using **Docker**, **Azure Container Registry (ACR)**, **Azure Container Apps**, and **Infrastructure as Code (IaC)** with Bicep.

## Course Objectives
By the end of this course, you will be able to:
1.  **Develop** and containerize a web application using Docker.
2.  **Securely push** and manage container images in a private Azure Container Registry (ACR).
3.  **Automate** infrastructure deployment using Azure Bicep and GitHub Actions.
4.  **Deploy and scale** applications to Azure Container Apps.
5.  **Manage traffic** and high availability with Azure Traffic Manager.

### Conceptual Model: The AKF Scaling Cube
This course is structured around the **AKF Scaling Cube**, a model for analyzing and improving the scalability of products.

*   **X-Axis (Horizontal Duplication)**: Cloning the application and data behind a load balancer. We cover this in **Lab 3** by running multiple replicas of our container.
*   **Y-Axis (Functional Decomposition)**: Splitting the application into smaller services/microservices. While our demo app is simple, containerization (Lab 1) is the first step towards this architecture.
*   **Z-Axis (Data Partitioning)**: Splitting data and customers, often by geography. **Lab 4 and 5** explore this by using **Azure Front Door** to route traffic globally, laying the foundation for geo-partitioning.

---

## Setup 1: Local Environment & Tools

Before touching the cloud, we need to set up your local development environment.

### 1. Development Tools
Install the following essential tools:
*   [**VS Code**](https://code.visualstudio.com/): Our code editor. Install the *Docker* and *Bicep* extensions.
*   [**Git**](https://git-scm.com/): For version control.
    ```bash
    git config --global user.name "Your Name"
    git config --global user.email "your.email@example.com"
    ```
*   [**Docker Desktop**](https://www.docker.com/products/docker-desktop): To build and run containers locally.
*   [**Azure CLI**](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli): To interact with Azure from your terminal.
    *   Verify installation: `az --version`
    *   Login: `az login`
*   [**Bicep CLI**](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install): To compile infrastructure templates.
    ```bash
    az bicep install
    ```

### 2. GitHub Setup
1.  **Fork this Repository**: Click the "Fork" button at the top right of this page to create your own copy. Name it `scalecloud`.
2.  **Clone Locally**:
    ```bash
    # Replace <your-username> with your actual GitHub username
    git clone git@github.com:<your-username>/scalecloud.git
    cd scalecloud
    ```

---

## Setup 2: Cloud Configuration (Azure & GitHub)

To automate deployments, we need to connect your GitHub repository to your Azure subscription securely.

### Option 1: Azure Portal Setup (Manual)
*(See steps A, B, and C above)*

### Option 2: Azure CLI Setup (Automated)
Instead of clicking through the portal, you can run this script in your terminal to set up everything at once.

**Prerequisite:** Ensure you are logged in (`az login`) and have selected the correct subscription (`az account set -s <SUBSCRIPTION_ID>`).

```bash
# Variables - Update these!
GITHUB_ORG="<your-github-username>"
GITHUB_REPO="scalecloud"
APP_NAME="github-actions-scalecloud"

# 1. Create Azure AD App Registration
APP_ID=$(az ad app create --display-name $APP_NAME --query appId -o tsv)

# 2. Create Service Principal for the App
SP_ID=$(az ad sp create --id $APP_ID --query id -o tsv)

# 3. Assign Contributor Role to the Subscription
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
az role assignment create --assignee $APP_ID --role Contributor --scope /subscriptions/$SUBSCRIPTION_ID

# 4. Create Federated Credential for 'main' branch
az ad app federated-credential create --id $APP_ID \
  --parameters "{\"name\":\"github-actions-main\",\"issuer\":\"https://token.actions.githubusercontent.com\",\"subject\":\"repo:$GITHUB_ORG/$GITHUB_REPO:ref:refs/heads/main\",\"description\":\"GitHub Actions for main branch\",\"audiences\":[\"api://AzureADTokenExchange\"]}"

# 5. Output Secrets for GitHub
echo ""
echo "--------------------------------------------------------"
echo "✅ Setup Complete! Add these to your GitHub Secrets:"
echo "--------------------------------------------------------"
echo "AZURE_CLIENT_ID:       $APP_ID"
echo "AZURE_TENANT_ID:       $(az account show --query tenantId -o tsv)"
echo "AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
echo "--------------------------------------------------------"
```

### 2. GitHub Secrets & Variables
Go to your forked repository on GitHub: **Settings** -> **Secrets and variables**.

#### A. Repository Secrets (Encrypted)
Under the **Actions** tab of *Secrets*, add the following:

| Secret Name | Value Description |
| :--- | :--- |
| **`AZURE_CLIENT_ID`** | The Application (client) ID from Step A. |
| **`AZURE_TENANT_ID`** | The Directory (tenant) ID from Step A. |
| **`AZURE_SUBSCRIPTION_ID`** | Your Azure Subscription ID (e.g., `abc-123-def-456`). |

#### B. Repository Variables (Visible)
Under the **Actions** tab of *Variables*, add:

| Variable Name | Value Description |
| :--- | :--- |
| **`ACR_NAME`** | The name of your Azure Container Registry (e.g., `myacr123`). *Create one in the portal if you haven't yet.* |
| **`ACR_IMAGE`** | The full path to your image in ACR (e.g., `myacr123.azurecr.io/scalingcloud:latest`). |
| **`AZURE_RESOURCE_GROUP`** | A base name for your resource groups (e.g., `rg-scalingcloud`). |

---

## Lab Workflow & Automation

This repository uses **GitHub Actions** to automate "Lab" setups. Instead of manually clicking in the portal, you will run workflows that deploy infrastructure code (Bicep) for you.

### How to Run a Lab (Deploy Infrastructure)
The workflow `Lab Bicep Deployment` handles the infrastructure creation for Labs 3, 4, and 5.

1.  Navigate to the **Actions** tab in your GitHub repository.
2.  Select **Lab Bicep Deployment** from the left sidebar.
3.  Click **Run workflow**.
4.  **Enter the Lab Number**: In the input field (e.g., `lab3`, `lab4`), type the folder name of the lab you want to deploy.
5.  Click the green **Run workflow** button.

*Effect: This triggers a job that logs into Azure, creates a resource group (e.g., `rg-scalingcloud-lab3`), and deploys the resources defined in that lab's `lab.bicep` file.*

### How to Deploy the Web App
When you make changes to the application code in `lab1/`:
1.  **Push your changes** to the `main` branch.
2.  The **`Build and push application`** workflow will automatically start.
3.  It builds your Docker image, logs into ACR, and pushes the new version.
4.  Your compliant Azure Container Apps will pull the new image and update automatically.

---

## Clean Up (Save Money!)

Cloud resources cost money. Always tear down your labs when you are done.

### Method 1: Automated Workflow
1.  Go to **Actions** -> **Delete Azure Resource Group**.
2.  Run the workflow.
3.  This script finds all resource groups tagged with `Project=scalingCloudLab` and deletes them.

### Method 2: Azure CLI
Run this command in your terminal to delete all lab groups instantly:
```bash
az group list --tag Project=scalingCloudLab --query "[].name" -o tsv | \
  xargs -I {} az group delete --name {} --yes --no-wait
```