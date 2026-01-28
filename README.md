# Scaling Cloud: Cloud-Native Applications with Azure & Docker

Welcome to the **Scaling Cloud** course! This repository is your hands-on guide to building, containerizing, and scaling modern web applications using **Docker**, **Azure Container Registry (ACR)**, **Azure Container Apps**, and **Infrastructure as Code (IaC)** with Bicep.

## Course Objectives
By the end of this course, you will be able to:
1.  **Develop** and containerize a web application using Docker.
2.  **Securely push** and manage container images in a private Azure Container Registry (ACR).
3.  **Automate** infrastructure deployment using Azure Bicep and GitHub Actions.
4.  **Deploy and scale** applications to Azure Container Apps.
5.  **Manage traffic** and high availability with Azure Traffic Manager.

### Conceptual Model: The AKF Scale Cube
This course is structured around the **AKF Scale Cube**, a model for analyzing and improving the scalability of products.

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

### 1. Fork & Clone
1.  **Fork this Repository**:
    *   Click the **Fork** button at the top right of this page.
    *   **Why?** This creates a complete copy of the project under **your own GitHub account**.
2.  **Clone Your Fork**:
    *   Download your new personal copy to your computer:
    ```bash
    # Replace <your-username> with your GitHub username
    git clone git@github.com:<your-username>/scalecloud.git
    cd scalecloud
    ```

### 2. Verify Local Environment
We have provided a script to verify your local environment (Git, Docker) is ready for **Lab 1 and Lab 2**.

1.  **Navigate to the `infra` folder**:
    ```bash
    cd infra
    ```
2.  **Run the Local Setup Script**:
    *   **Mac/Linux**:
        ```bash
        ./setup-local.sh
        ```
    *   **Windows**:
        ```powershell
        ./setup-local.ps1
        ```

This script will check if you have the necessary tools installed. If anything is missing, it will let you know what to install (Docker, Git, VS Code).

### Troubleshooting: Installation without Admin Rights
If you are on multiple-user machine (like a school or work laptop) and cannot install the Azure CLI (`az`) or GitHub CLI (`gh`) because of admin restrictions, try one of these methods:

**Option 1 (Recommended): Scoop**
[Scoop](https://scoop.sh) is a command-line installer for Windows that installs programs to your user folder, bypassing admin requirements.
```powershell
# 1. Install Scoop
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression

# 2. Install Tools
scoop install gh
scoop install azure-cli
```

**Option 2: Manual "Portable" Install**
You can download "portable" ZIP versions of these tools, unzip them, and add them to your user path.
*   **Azure CLI**: Download from [Official MS Docs (ZIP)](https://aka.ms/installazurecliwindowszipx64).
*   **GitHub CLI**: Download `..._windows_amd64.zip` from [GitHub Releases](https://github.com/cli/cli/releases).

---

## Setup 2: Cloud Configuration (Automated)

We use a setup script to configure the connection between GitHub and Azure. This is required for **Lab 3, 4, and 5**.

1.  **Prerequisites**:
    *   Ensure you have [**Azure CLI**](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) and [**GitHub CLI**](https://cli.github.com/) installed.
    *   **Login**:
        ```bash
        az login
        gh auth login
        ```

2.  **Configure your environment**:
    *   **Edit /config.env**:
        Review the `<changeme>` environment variables in the `config.env` file; the rest can be kept as-is.

        ```
        # 1. Azure Resource Settings
        RG_NAME="rg-scalingcloud-lab"        # Resource Group Name
        LOCATION="swedencentral"             # Azure Region
        ACR_NAME="<changeme>"                # Registry Name (Must be globally unique!)

        # 2. GitHub Settings
        GH_ORG="<changeme>"                  # Your GitHub Username/Org
        GH_REPO="scalingcloud"               # Your Repository Name
        GH_BRANCH="main"                     # Your Branch (usually main or master)
        ```

3.  **Run the Cloud Setup Script**:
    *   **Mac/Linux**:
        ```bash
        cd infra
        ./setup-cloud.sh
        ```
    *   **Windows**:
        ```powershell
        cd infra
        .\setup-cloud.ps1
        ```

This script will automate the creation of Identities, Role Assignments, and Configuration.

---


### Setup 2.5: Alternative - Cloud-Only (GitHub Codespaces)
If you cannot install tools locally, you can run the entire course directly in your browser using **GitHub Codespaces**.

1.  **Start Codespace**:
    *   Click the **Code** green button -> **Codespaces** -> **Create codespace on main**.
    *   This spins up a remote machine with Docker, Azure CLI, and GitHub CLI pre-installed (defined in `.devcontainer`).
2.  **Login inside Codespace**:
    *   Open the terminal (Ctrl+`).
    *   `unset GITHUB_TOKEN` (Crucial: Removes the default restricted token).
    *   `az login` (Follow the device code prompt).
    *   `gh auth login` (Select GitHub.com, SSH, and your key).
3.  **Run Setup Scripts**:
    *   Local Setup (for Lab 1/2): `cd infra && ./setup-local.sh`
    *   Cloud Setup (for Lab 3+): `cd infra && ./setup-cloud.sh`

---

## Setup 3: Understanding the Automation (Manual Guide)

If you prefer to understand what `setup-cloud.sh` does under the hood, or want to do it manually, here is the step-by-step process it performs:

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

### 7. Manual Setup (Portal & UI)
If you cannot run the scripts or prefer to click through the Azure Portal and GitHub UI, follow these steps:

1.  **Create Resource Group**:
    *   Go to Azure Portal -> **Resource groups** -> **Create**.
    *   Name it (e.g., `rg-scalingcloud-shared`) and select a region.

2.  **Create Managed Identity (Infra)**:
    *   Search for **Managed Identities** -> **Create**.
    *   Name: `id-github-infra`. Resource Group: `rg-scalingcloud-shared`.
    *   **Assign Role**: Go to your Resource Group -> **Access control (IAM)** -> **Add role assignment**.
    *   Role: `Owner`. Assign to: `Managed Identity` -> Select `id-github-infra`.

3.  **Federate Identity (OIDC)**:
    *   Go to the Managed Identity `id-github-infra` -> **Federated credentials** -> **Add credential**.
    *   Scenario: **GitHub Actions deploying Azure resources**.
    *   Organization: `your-github-username`. Repository: `scalecloud`. Branch: `main`.
    *   Name: `github-federation`.

4.  **Create Container Registry**:
    *   Search for **Container registries** -> **Create**.
    *   Name: Unique name (e.g., `sodalabs001`). Resource Group: `rg-scalingcloud-shared`. SKU: `Basic`.

5.  **Configure GitHub Secrets**:
    *   Go to your GitHub Repo -> **Settings** -> **Secrets and variables** -> **Actions**.
    *   Add **New repository secret**:
        *   `AZURE_CLIENT_ID_INFRA`: Client ID of `id-github-infra`.
        *   `AZURE_TENANT_ID`: Tenant ID from Azure Active Directory.
        *   `AZURE_SUBSCRIPTION_ID`: Your Subscription ID.

6.  **Configure GitHub Variables**:
    *   Go to **Variables** tab -> **New repository variable**.
    *   Add variables from your `config.env` (e.g., `RG_NAME`, `ACR_NAME`, `LOCATION`).

---



## Lab Workflow & Automation

This repository uses **GitHub Actions** to automate "Lab" setups. Instead of manually clicking in the portal, you will run workflows that deploy infrastructure code (Bicep) for you.

### How to Run a Lab (Deploy Infrastructure)
**CRITICAL: Push Lab 1 First!**
Labs 3, 4, and 5 *depend* on the container image from Lab 1. Before running any lab deployment:
1.  Navigate to `lab1/` code.
2.  Make a small change (or just push the folder).
3.  Ensure the **`Build and push application`** workflow runs successfully.
*Without this, your Azure Container Apps will fail to start because they cannot find the image.*

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
Run the `nuke` script in your terminal to delete all lab groups instantly:

*   **Mac/Linux**:
    ```bash
    ./infra/nuke.sh
    ```
*   **Windows**:
    ```powershell
    ./infra/nuke.ps1
    ```

(Or run manually via CLI commands below)
```bash
az group list --tag Project=scalingCloudLab --query "[].name" -o tsv | \
  xargs -I {} az group delete --name {} --yes --no-wait
```

---

## Key Files & Structure

Here is a quick overview of the most important files in this repository:

### 📂 Infrastructure (`infra/`)
This folder contains the core setup for the course environment.
*   **`setup-local.sh` / `setup-local.ps1`**: Checks if your local environment (Git, Docker) is ready.
*   **`setup-cloud.sh` / `setup-cloud.ps1`**: The "one-click" cloud setup script. It configures Azure Resources, Identities, and GitHub Secrets.
*   **`config.env`**: The configuration file where you define your custom names (Registry name, Location, Resource Groups).
*   **`main.bicep`**: The core Infrastructure-as-Code template. It deploys persistent shared resources like the Azure Container Registry (ACR) and Managed Identities.
*   **`nuke.sh` / `nuke.ps1`**: A "clean slate" utility (Bash/PowerShell). **WARNING**: This script deletes all Resource Groups created by this course to stop costs.

### 📂 Workflows (`.github/workflows/`)
Automation pipelines that run in GitHub Actions.
*   **`infra.yml`**: Automatically deploys changes to the core infrastructure (`infra/main.bicep`) when you push to `main`.
*   **`build-and-deploy-app.yml`**: Triggered by changes in `lab1/`. It builds the Docker image, pushes it to ACR, and updates the Container App.
*   **`lab-bicep-deploy.yml`**: A manual workflow (Workflow Dispatch) used to deploy specific lab infrastructure (e.g., "Deploy Lab 3").
*   **`tare-down-workflow.yml`**: A manual workflow to delete lab resource groups directly from GitHub.

### 📂 Labs
*   **`lab1/`**: Contains the source code for the Node.js application and its Dockerfile.
*   **`lab3/` - `lab5/`**: Contains the Bicep templates (`lab.bicep`) for advanced scaling scenarios (Replicas, Traffic Manager, Front Door).
