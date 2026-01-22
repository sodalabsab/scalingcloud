# Lab 5 - Testing Azure Front door globally

This lab demonstrates latencies Azure Front Door by deploying a simple Container that runs load tests.
The setup is a bit quirqy when it comes to javascript code for the loadtest to simplify the deployment. 

## Contents

- **lab.bicep** A Bicep file that declares a single Container that executes a loadscript using K6.

### Prerequisites
- Setup 2 from the readme at the root of to reposiroty must have been done and verified

### Execution
1. Find the URL to the frontdoor in lab4. Past that into the javascript code that is in the bicep file `lab.bicep`
2. Commit the change and push it to github.
3. Go to the "action" tab in your GitHub account and select the `Lab bicep deployment` workflow to the left
4. Click on the "Run workflow" button and specify `lab5` Lab nr (That is the default)
5. Select "Run Workflow" and refresh the page to se the newly started workflow execution
    If you click on the "Deploy" stage, it will open up and you can follow the progres of the deployemnt. If something fails, look at the error message and figure out if there is something in the setup (readme at the root of to reposiroty) that is wrong.


### Accessing the Application
6. Once everything is complete, attach the azure cli to the log output from the container: 
    ```bash
    az container logs --resource-group <resource-group-name> --name k6-container
    ```
    Take notice to the result. 
    Repeate from nr 1. using the direct URL to the application and compare the results in responstime.

### Acceptance Criteria
*   The K6 container deploys successfully to Azure.
*   You can view the logs (`az container logs`) and see the latency results for both Direct Access and Front Door Access.

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
