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

## Setup 0: Accounts (Free)

Before we start, ensure you have the following accounts. Both offer free tiers perfect for this course.

1.  **GitHub Account**:
    *   [Sign up for GitHub](https://github.com/join).
    *   This is where your code and workflows will live.
2.  **Azure Account**:
    *   [Create a free Azure Account](https://azure.microsoft.com/en-us/free/).
    *   Azure gives you $200 credit for the first 30 days and 12 months of popular free services.

---

## Setup 1: Local Environment & Tools

We need a few CLI tools to interact with the cloud.

### 1. Development Tools
Install the following essential tools:
*   [**VS Code**](https://code.visualstudio.com/): Our code editor. Install the *Docker* and *Bicep* extensions.
*   [**Git**](https://git-scm.com/): For version control.
*   [**Docker Desktop**](https://www.docker.com/products/docker-desktop): To build and run containers locally.
*   [**Azure CLI**](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli): To manage Azure resources.
*   [**GitHub CLI (gh)**](https://cli.github.com/): To manage your repository and secrets from the terminal.
*   [**Bicep CLI**](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install):
    ```bash
    az bicep install
    ```

### 2. Login
Once installed, open your terminal and authenticate:

1.  **Login to Azure**:
    ```bash
    az login
    ```
2.  **Login to GitHub**:
    ```bash
    gh auth login
    ```
    *   Select `GitHub.com` -> `SSH` (recommended) or `HTTPS` -> `Login with a web browser`.

### 3. Clone Repository
1.  **Fork this Repository**:
    *   Click the **Fork** button at the top right of this page.
    *   **Why?** This creates a complete copy of the project under **your own GitHub account**. You need this to successfully run your own automation workflows, manage your own secrets, and make changes without affecting the original course repository.
2.  **Clone Your Fork**:
    *   Download your new personal copy to your computer:
    ```bash
    # Replace <your-username> with your GitHub username
    git clone git@github.com:<your-username>/scalecloud.git
    cd scalecloud
    ```

---

## Setup 2: Cloud Configuration (Automated)

We use a bootstrap script to set up the connection between GitHub and Azure. This automates the creation of Identities, Role Assignments, and Configuration.

1.  **Navigate to the `infra` folder**:
    ```bash
    cd infra
    ```
2.  **Configure Environment**:
    *   Edit this file named `config.env` using your preferred text editor.
    *   Define your variables (Resource Group name, Location, etc.) in this file.
3.  **Run the Bootstrap Script**:
    ```bash
    ./bootstrap.sh
    ```

This script will output the created resources and verify that your GitHub Secrets have been set correctly.

---

## Setup 3: Understanding the Automation (Manual Guide)

If you prefer to understand what `bootstrap.sh` does under the hood, or want to do it manually, here is the step-by-step process it performs:

### 1. Pre-flight Checks
*   Verifies that `az` and `gh` CLIs are installed and logged in.
*   Loads variables from your `config.env` file.

### 2. Resource Group Creation
*   Creates an Azure Resource Group to hold all shared infrastructure (like the Container Registry).

### 3. Identity Setup (OIDC)
*   **Infrastructure Identity**: Creates an Azure User-Assigned Managed Identity. This identity is used by GitHub Actions to deploy infrastructure (Bicep).
*   **Role Assignment**: Assigns the `Owner` role to this identity on the Resource Group, allowing it to create and manage resources.
*   **Federation**: Establishes a trust relationship (OIDC) between the Identity and your GitHub repository's `main` branch. This eliminates the need for storing passwords.

### 4. GitHub Secrets Configuration (Infra)
*   Sets the following secrets in your GitHub repo:
    *   `AZURE_SUBSCRIPTION_ID`
    *   `AZURE_TENANT_ID`
    *   `AZURE_CLIENT_ID_INFRA` (The ID of the identity we just created)

### 5. Initial Deployment & App Setup
*   Runs `main.bicep` to deploy the Azure Container Registry and other core resources.
*   **App Identities**: The Bicep deployment creates separate identities for the Application (Push/Pull).
*   **App Secrets**: The script fetches the `App Push Identity` Client ID and saves it as `AZURE_CLIENT_ID` in GitHub Secrets.

### 6. Variable Configuration
*   Finally, it saves your configuration (Resource names, Location) as **GitHub Variables** so your workflows can reference them automatically.

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

---

## Key Files & Structure

Here is a quick overview of the most important files in this repository:

### 📂 Infrastructure (`infra/`)
This folder contains the core setup for the course environment.
*   **`bootstrap.sh`**: The "one-click" setup script. It configures Azure Resources, Identities, and GitHub Secrets automatically.
*   **`config.env`**: The configuration file where you define your custom names (Registry name, Location, Resource Groups).
*   **`main.bicep`**: The core Infrastructure-as-Code template. It deploys persistent shared resources like the Azure Container Registry (ACR) and Managed Identities.
*   **`nuke.sh`**: A "clean slate" utility. **WARNING**: This script deletes all Resource Groups created by this course to stop costs.

### 📂 Workflows (`.github/workflows/`)
Automation pipelines that run in GitHub Actions.
*   **`infra.yml`**: Automatically deploys changes to the core infrastructure (`infra/main.bicep`) when you push to `main`.
*   **`build-and-deploy-app.yml`**: Triggered by changes in `lab1/`. It builds the Docker image, pushes it to ACR, and updates the Container App.
*   **`lab-bicep-deploy.yml`**: A manual workflow (Workflow Dispatch) used to deploy specific lab infrastructure (e.g., "Deploy Lab 3").
*   **`tare-down-workflow.yml`**: A manual workflow to delete lab resource groups directly from GitHub.

### 📂 Labs
*   **`lab1/`**: Contains the source code for the Node.js application and its Dockerfile.
*   **`lab3/` - `lab5/`**: Contains the Bicep templates (`lab.bicep`) for advanced scaling scenarios (Replicas, Traffic Manager, Front Door).