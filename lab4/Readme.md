# Lab 4 - Deploying a Azure Front door to Azure with Bicep

This lab demonstrates Azure Front Door by deploying a simple Container App and Azure Front Door to Azure using Bicep and GitHub actions.

**AKF Connection (X/Z-Axis)**: Azure Front Door is a global load balancer. It enables **Global X-Axis** scaling by allowing you to place replicas in different regions and balance traffic between them. It also enables **Z-Axis** scaling (Data Partitioning) by allowing you to route specific customers (e.g., based on geography) to specific processing units closest to them.

## Contents

- **lab.bicep** A Bicep file that declares a Container App and Azure FrontDoor in Azure.

### Prerequisites
- Setup 2 from the readme at the root of to reposiroty must have been done and verified

### Execution
1. Go to the "action" tab in your GitHub account and select the `Lab bicep deployment` workflow to the left
2. Click on the "Run workflow" button and specify `lab4` Lab nr (That is the default)
3. Select "Run Workflow" and refresh the page to se the newly started workflow execution
    If you click on the "Deploy" stage, it will open up and you can follow the progres of the deployemnt. If something fails, look at the error message and figure out if there is something in the setup (readme at the root of to reposiroty) that is wrong.

4. Once everything is complete, login to Azure Portal and investigate at the created resource group
5. Find the URL of the FrontDoor endpoint (should look like `https://afd-<random>.z01.azurefd.net`).

### Verification & Troubleshooting
1.  **Check Origin Health**:
    *   In the Azure Portal, go to your **Front Door and CDN profiles** resource.
    *   Click **Origin groups** -> **MyOriginGroup**.
    *   Check the "Percentage" or health status. It should be 100%. If it is 0%, Front Door cannot reach your Container App.
2.  **Verify HTTPS**:
    *   Copy the Front Door URL.
    *   Open it in your browser. It should load the "Massively" or "Hacked" website securely (Lock icon).
    *   Try accessing with `http://...`. It should automatically redirect to `https://...`.
3.  **Troubleshooting Connection Issues**:
    *   **503 Service Unavailable**: Usually means the Origin (Container App) is unhealthy or unreachable.
        *   *Fix*: Check the Origin Group health probes. Ensure the Container App is running and responding to HTTPS requests.
    *   **502 Bad Gateway**: Front Door reached the app but got an invalid response.
        *   *Fix*: Ensure the `hostHeader` matches the Container App's FQDN (this is handled in the Bicep).
    *   **Certificate Errors**: Ensure you are accessing the specific Front Door URL, not the generic one if you haven't set up custom domains.

### Accessing the Application
### Acceptance Criteria
*   You can access the application via the Azure Front Door URL (not just the direct Container App URL).
*   The site loads securely via HTTPS.

### Shutdown Instructions
**Important**: Delete the resource group to stop incurring costs.
*   **Option 1 (GitHub Actions)**: Run the "Delete Azure Resource Group" workflow manually.
*   **Option 2 (Azure CLI)**:
    ```bash
    az group list --tag Project=scalingCloudLab --query "[].name" -o tsv | xargs -I {} az group delete --name {} --yes --no-wait
    ```

## File Structure
```bash
.
├── lab.bicep           # Bicep file that declares a Container App in Azure
├── load.js             # K6 script for load testing
└── README.md           # Project documentation
```
