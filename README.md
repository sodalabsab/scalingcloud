# Scaling Cloud Course

This course will guide you through scaling cloud applications using Docker and Azure services, with a focus on Bicep deployments. Below are detailed instructions for cloning the course code, setting up your local environment, configuring and integrating accounts, and deploying infrastructure and applications.

---

## Setup 1

### Tools and Accounts Setup for lab 1 and 2

1. **Microsoft Visual Studio Code (VS Code)**
   - Download and install from: [https://code.visualstudio.com/](https://code.visualstudio.com/)
   - Install helpful extensions: Docker and Git.

2. **Git (if that is not already on your computer)**
   - Download and install from: [https://git-scm.com/](https://git-scm.com/)
   - Configure Git with your name and email:
     ```bash
     git config --global user.name "Your Name"
     git config --global user.email "your.email@example.com"
     ```
   - Verify Git installation:
     ```bash
     git --version
     ```

3. **GitHub Account**
   - Sign up: [https://github.com/join](https://github.com/join)
   - Configure a Personal Access Token for GitHub Actions:
     - Go to **Settings** > **Developer settings** > **Personal access tokens**.

4. **Clone the course Repository into your GitHub Account**
   - In your GitHub home screen, click on the small + sign top right
   - Select "Import repository" paste the [URL of the course reporitory](https://github.com/sodalabsab/scalingcloud.git)
   - Name the repository "scalecloud" and select private, this will import the course code into your account, giving you a local copy

5. **Download the repository localy**
   - Go to the newly created repo in your github account and click on the green "<>Code" button. Copy the SSH URL:
     ```bash
     git clone git@github.com:<your-username>/scalecloud.git
     ```
   - Replace `<your-username>` with your GitHub username.
   - Change directory into the repo:
     ```bash
     cd scalecloud
     ```
   - Verify the repo with the command
     ```bash
     git remove -v
     ```  
     You sould see something like: `origin	git@github.com:danielfroding/scalcloud.git (push)`

6. **Docker (requires local admin)**
   - Download and install from: [https://www.docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop)
   - Ensure Docker is running and verify installation:
     ```bash
     docker --version
     ```
7. **DockerHub**
   - Login or sign up for a DockerHub account at [https://www.dockerhub.com/](https://www.dockerhub.com/)

7. **Open the code in VS Code**
   - Start VS Code and open the directory by selecting "Open folder..." from the File meny

# Setup 2 - move to the cloud

This part explores some of the avaliable tools to build, deploy and monitor applications in Azure. There are a few things required to be setup to be able to run the labs. 

1. **Azure Account**
   - Sign up: [https://azure.microsoft.com/free/](https://azure.microsoft.com/free/)
   - Ensure your subscription is active (you should be able to create a free tier subscriptioin)

2. **(Optional) Azure CLI**
   - Install from: [https://docs.microsoft.com/en-us/cli/azure/install-azure-cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
   - Log in to your Azure account:
     ```bash
     az login
     ```

7. **(Optional) Bicep CLI**
   - Install Bicep using Azure CLI:
     ```bash
     az bicep install
     ```
   - Verify Bicep installation:
     ```bash
     az bicep version
     ```

## GitHub actions Setup for Azure Bicep Deployment

### Configure GitHub Secrets

You need to configure the following GitHub Secrets in your repository for secure deployment. These secrets are referenced in the actions workflows and in bicep files.

#### Steps to Configure Secrets

1. Go to your repository's **Settings**.
2. Navigate to **Secrets and variables** > **Actions**.
3. Add the following secrets:
   - `AZURE_SUBSCRIPTION_ID`: Your Azure subscription ID.
   - `AZURE_RESOURCE_GROUP`: Provide a suitable name of the resource groups that will be created and used for the labs.
   - `DOCKERHUB_PASSWORD`: Your password to dockerhub.com (used for rebuilding and pushing a new version of `my-website`) 
   - `DOCKERHUB_IMAGE`: The name of your image that ws pushed to dockerhub.com in lab1. It will be used as input into the bicep file that sets up the labs in azure.  

### Setting Up Azure Credentials in GitHub

To deploy Azure resources using GitHub Actions, you need to create and configure Azure credentials securely in your GitHub repository. We need to create a service principal (server account) in Azure and give to GitHub to allow access from GitHub Actions into Azure. Here's how to do it:

1. **Create a Service Principal**
   - Run the following command to create a new service principal and capture the output, which includes your `appId`, `password`, and `tenant`:
     ```bash
     az account show --query id --output tsv 
     az ad sp create-for-rbac --name "github-actions-deploy" --role contributor --scopes /subscriptions/<AZURE_SUBSCRIPTION_ID> --sdk-auth
     ```
   - Replace `<AZURE_SUBSCRIPTION_ID>` with your actual Azure subscription ID from the first command. (You can also find the subscription ID in the portal)
   - The output will look like this:
     ```json
     {
       "appId": "YOUR_APP_ID",
       "displayName": "github-actions-deploy",
       "password": "YOUR_PASSWORD",
       "tenant": "YOUR_TENANT_ID"
     }
     ```

3. **Store Azure Credentials in GitHub Secrets**
   - Go to your GitHub repository and navigate to **Settings**.
   - Under **Secrets and variables**, click on **Actions**.
   - Click **New repository secret** and add a secret named `AZURE_CREDENTIALS`.
   - Past in the JSON ouput from step 2 so that `AZURE_CREDENTIALS` secret is a JSON string containing your credentials.

---

## Running the Azure labs

The GitHub Actions workflow `.github/workflows/lab-bicep-deploy.yml` is designed to deploy Azure resources using Bicep files located in specific directories for Labs 3, 4, and 5. It allows you to specify which lab's Bicep file to deploy using manual workflow dispatch.
This allows you to trigger the workflow and provide an input specifying the lab number (`labPath`), which points to the directory where the Bicep file is located. By default, it deploys the Bicep file for `lab3`.

### Environment Variables

- `AZURE_SUBSCRIPTION_ID`: Retrieved from GitHub Secrets and used to identify your Azure subscription.
- `AZURE_CREDENTIALS`
- `RESOURCE_GROUP`: The name of the Azure resource group, dynamically constructed using the lab path input. It appends the lab number to the base resource group name.
- `LOCATION`: Set to `swedencentral`, which is the default location for all resources.


### Jobs and Steps

The workflow contains a single job, `deploy`, that runs on an `ubuntu-latest` virtual environment and executes the following steps:

1. **Checkout Repository**
   - **Action**: `actions/checkout@v2`  
     This step checks out the code from the repository, making the Bicep files available for deployment.

2. **Log in to Azure**
   - **Action**: `azure/login@v1`  
     This step logs into your Azure account using the credentials stored in GitHub Secrets (`AZURE_CREDENTIALS`). This is necessary to authenticate and interact with Azure resources.

3. **Ensure the Resource Group Exists**
   - **Command**: 
     ```bash
     az group create --name ${{ env.RESOURCE_GROUP }} --location ${{ env.LOCATION }} --subscription ${{ secrets.AZURE_SUBSCRIPTION_ID }} --tags Project=scalingCloudLab
     ```
   - **Description**: This command creates the resource group if it does not already exist. It uses the `RESOURCE_GROUP` environment variable, which incorporates the lab path, and assigns a tag `Project=scalingCloudLab` to the resource group.

4. **Deploy Bicep File for the Specified Lab**
   - **Command**:
     ```bash
     az deployment group create --resource-group ${{ env.RESOURCE_GROUP }} --subscription ${{ secrets.AZURE_SUBSCRIPTION_ID }} --template-file ${{ github.event.inputs.labPath }}/lab.bicep --mode Incremental
     ```
   - **Description**: This command deploys the Bicep file for the specified lab. It uses the `az deployment group create` command to deploy the infrastructure defined in the `lab.bicep` file located in the directory specified by the `labPath` input. The `--mode Incremental` flag ensures that existing resources are not deleted and only new or updated resources are deployed.

---

### How to Use

1. **Trigger the Workflow Manually**:
   - Navigate to the **Actions** tab in your GitHub repository.
   - Select the **Lab Bicep Deployment** workflow.
   - Click on **Run workflow** and specify the `labPath` input (e.g., `lab3`, `lab4`, or `lab5`) to choose which lab's Bicep file to deploy.

2. **Bicep Deployment**:
   - The workflow will create or update the Azure resource group and then deploy the infrastructure using the appropriate Bicep file.

---

### Notes

- **Resource Group Naming**: The resource group name is constructed dynamically, combining a base name with the lab number. This helps in organizing resources by lab.
- **Incremental Deployment**: The `--mode Incremental` flag ensures that only changes are applied, preventing the deletion of existing resources.

This workflow provides a structured and automated way to manage Azure deployments for multiple labs, making it easy to set up and scale cloud infrastructure.
## Deploying the Test WebApp

You can deploy the test web application by:

1. **Pushing a Change**: Any change in the repository (e.g., code or configuration updates) will automatically trigger the deployment workflow.
2. **Manually Triggering**: Use the **`webapp-workflow`** in GitHub Actions to manually deploy the web app.

This will build and deploy the web application to your Azure environment.

---

## Tearing Down the Environment

To remove all resources and delete the resource groups created in the labs. They all have the tag: `Project=scalingCloudLab`

There are two ways to delete all of them. 
1. Go to the "action" tab in your GitHub account and select the `Lab bicep deployment` workflow to the left, click on "Run workflow", this will start a workflow that thoes the same thing as described below:
2. If you have Azure CLI and is loggedin to your subscription run this command in a terminal:

```bash
az group list --tag Project=scalingCloudLab --query "[].name" -o tsv | xargs -I {} az group delete --name {} --yes --no-wait
```