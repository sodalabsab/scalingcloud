# Lab 5 - Testing Azure Front door globally

This lab demonstrates latencies Azure Front Door by deploying a simple Container that runs load tests.
The setup is a bit quirky when it comes to javascript code for the loadtest to simplify the deployment. 

## Contents

- **lab.bicep** A Bicep file that declares a single Container that executes a loadscript using K6.

### Prerequisites
- Setup 2 from the readme at the root of the repository must have been done and verified

### Execution
1. Find the URL to the frontdoor in lab4. Paste that into the javascript code that is in the bicep file `lab.bicep`.
2. Commit the change and push it to GitHub.

**Option 1: GitHub UI**
1. Go to the "Actions" tab in your GitHub repository.
2. Select the **Lab bicep deployment** workflow.
3. Run the workflow, ensuring `lab5` is specified.
4. Wait for completion.

**Option 2: GitHub CLI**
You can trigger and monitor the deployment directly from your terminal:
```bash
# Trigger the workflow
gh workflow run lab-bicep-deploy.yml -f labPath=lab5

# Watch the execution (select the latest run)
gh run watch

# View the logs to see the "Deployment Outputs"
gh run view --log | grep -A 10 "Deployment Outputs"
```


### Accessing the Application
6. Once everything is complete, attach the azure cli to the log output from the container: 
    ```bash
    az container logs --resource-group <resource-group-name> --name k6-container
    ```
    Take notice to the result. 
    Repeat from nr 1 using the direct URL to the application and compare the results in response time.

### Acceptance Criteria
*   The K6 container deploys successfully to Azure.
*   You can view the logs (`az container logs`) and see the latency results for both Direct Access and Front Door Access.

## File Structure
```bash
.
├── lab.bicep           # Bicep file that declares a Container App in Azure
├── load.js             # K6 script for load testing
└── README.md           # Project documentation
```
