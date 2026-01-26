# Lab 4 - Azure Front Door with Multiple Origins

This lab demonstrates **Global X-Axis Scaling** (Horizontal Duplication) using Azure Front Door. We will deploy **two separate Container App instances** and place Azure Front Door in front of them as a global load balancer.

You will also learn how to monitor traffic in real-time by streaming **access logs** from the containers while generating load.

## Contents

- **`lab.bicep`**: Defines the infrastructure:
    -   Log Analytics Workspace (for logs).
    -   Container App Environment (monitoring enabled).
    -   **Two** Container Apps (`my-website-1` and `my-website-2`).
    -   Azure Front Door Profile, Endpoint, Origin Group (with 2 origins), and Route.
- **`load.js`**: A K6 script to simulate traffic against the Front Door endpoint.

## Prerequisites

- **Setup 2** from the [root README](../README.md) must be completed (Azure creds configured).
- **K6** installed locally for load testing.

## Execution

### 1. Deploy Infrastructure
1.  Go to the **Actions** tab in your GitHub repository.
2.  Select the **Lab bicep deployment** workflow.
3.  Run the workflow, ensuring `lab4` is selected.
4.  Wait for completion.

### 2. Gather Information
Once deployed, go to the Azure Portal or check the deployment outputs in GitHub/CLI to find:
*   **Front Door URL**: `https://afd-<unique>.z01.azurefd.net`
*   **App Names**: `my-website-1`, `my-website-2`
*   **Resource Group Name**: The one created by the workflow.

### 3. Real-Time Access Logs
To verify traffic is reaching both containers, we will stream their logs. Open **two separate terminal windows**:

**Terminal 1 (Stream logs for App 1):**
```bash
az containerapp logs show --name my-website-1 --resource-group <YourResourceGroup> --follow
```

**Terminal 2 (Stream logs for App 2):**
```bash
az containerapp logs show --name my-website-2 --resource-group <YourResourceGroup> --follow
```

*(Note: Requires Azure CLI installed and logged in via `az login`)*

### 4. Load Testing & Balancing
In a **third terminal**, run the K6 load test against your Front Door URL. This will generate traffic which Front Door should distribute between the two apps.

```bash
k6 run -e TARGET_URL=https://<your-frontdoor-url> load.js
```

**Observation:**
*   Watch the K6 output statistics.
*   Watch Terminal 1 and 2. You should see access log entries appearing in BOTH terminals, proving that Front Door is load balancing the requests.

## Architecture & Concepts

*   **Front Door**: Acts as the entry point. It terminates SSL and routes clean HTTP/S traffic to the backends.
*   **Origins**: We have two distinct apps acting as origins. In a real-world scenario, these could be in different Azure regions (e.g., East US and West Europe) to reduce latency for global users.
*   **Health Probes**: Front Door constantly pings the apps. If you stop one app (`az containerapp stop ...`), Front Door will detect the failure and route all traffic to the remaining healthy app.

## Troubleshooting

1.  **503 Service Unavailable**:
    *   Origins might be starting up. Check Origin Group health in Azure Portal.
    *   Ensure Health Probes are passing (defaults to checking `/`).
2.  **No Logs appearing**:
    *   Ensure you are looking at the correct container app name.
    *   It might take a minute for the log stream to connect.

## Shutdown

**Important**: Delete the resource group to stop incurring costs.

**Option 1 (GitHub Actions)**: Run the "Delete Azure Resource Group" workflow.

**Option 2 (Azure CLI)**:
```bash
az group list --tag Project=scalingCloudLab --query "[].name" -o tsv | xargs -I {} az group delete --name {} --yes --no-wait
```
