# Azure Container Apps & CI/CD Lab

This project serves as a practical lab for developers to learn how to deploy containerized applications to Azure Container Apps (ACA) using modern "Platform Engineering" practices and GitHub Actions.

## 🎓 Lab Overview

In this lab, you will act as both a **Platform Engineer** and a **Product Developer**.

1.  **Platform Engineering**: You will bootstrap a shared infrastructure (Azure Container Registry, Managed Environment, Log Analytics) that acts as the "deployment target".
2.  **Product Development**: You will set up a CI/CD pipeline to deploy a web application to this infrastructure automatically on every code change.

### Architecture

*   **`infra/platform/`**: Contains Bicep code for long-lived infrastructure (ACR, Env).
*   **`infra/app/`**: Contains Bicep code for the application service itself.
*   **`src/`**: The simple HTML application.
*   **`.github/workflows/`**: The CI/CD pipeline definition.

---

## 🛠️ Lab Instructions

### Prerequisites
*   **Azure CLI**: Logged in (`az login`).
*   **GitHub CLI**: Logged in (`gh auth login`).
*   **Git**: Installed.

### Step 1: Platform Setup (Infrastructure)
Run the setup script to provision the Azure infrastructure. This mimics the work a Platform team would do for you.

```bash
./setup.sh
```
*Wait for this to complete.* It will output several secret values (ACR Name, Environment ID). **Keep these safe**, you will need them only if you configure secrets manually.

### Step 2: Product Setup (CI/CD)
Run the GitHub setup script. This will initialize your git repo, create it on GitHub, and importantly, **configure all necessary GitHub Actions Secrets** for you automatically.

```bash
./github_setup.sh
```

### Step 3: Verify Deployment
1.  Go to your new repository on GitHub.
2.  Click the **Actions** tab.
3.  Watch the `Deploy to Azure Container Apps` workflow run.
4.  Once green, check the "Deploy Container App" step logs to find your Application URL!

---

## 🔄 Reset / Teardown (Start Over)

To completely clear this lab and start from scratch (e.g., for a new student or a fresh run), use the teardown script.

**⚠️ WARNING**: This destroys the Azure Resource Group and the GitHub Repository.

```bash
./teardown.sh
```

### Manual Teardown Steps
If you prefer to do this manually:
1.  **Delete Azure Resources**: `az group delete --name rg-aca-platform --yes --no-wait`
2.  **Delete GitHub Repo**: `gh repo delete <your-username>/aca-demo --yes`
3.  **Reset Local Git**: `rm -rf .git`

> **Note**: If `gh repo delete` fails with a 403 error, you need to grant the CLI permission to delete repositories. Run:
> `gh auth refresh -h github.com -s delete_repo`

---

## 🏫 Instructor Notes

*   **Secrets Handling**: The `github_setup.sh` script attempts to automatically set secrets. In a classroom setting, ensure students have a Service Principal created or guide them to create one using:
    ```bash
    az ad sp create-for-rbac --name "aca-lab-student" --role contributor --scopes /subscriptions/<sub-id>/resourceGroups/rg-aca-platform --sdk-auth
    ```
    They will need to export this as `AZURE_CREDENTIALS` before running the github setup script if the script doesn't handle creation.
*   **Cost**: This lab uses the Basic SKU for ACR and Consumption plan for ACA, which is very cost-effective. Remember to tear down resources after the workshop to stop billing.
