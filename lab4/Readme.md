# Lab 4 - Deploying a Azure Front door to Azure with Bicep

This lab demonstrates Azure Front Door by deploying a simple Container App and Azure Front Door to Azure using Bicep and GitHub actions.

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

5. Find the application metrics under **Monitoring->Metrics** and create a new metrics diagram by selecting **Replica count** in the Metric dropdown

    You should now see 3 started replicas. In the bicep file we stated that it should scale to max 20 replicas if there were more than 20 HTTP requests in parallel. To simulate this, we ask K6 to toadtest the application.

6. Copy the URL of the application and past in in to the load.js file in VS Code. Open a terminal and run the test
    ```bash
    k6 run load.js
    ```
7. Follow the metric to see if the number of instances increases. There is a bit of delay so it might take a couple of minutes.
8. After the loadtest has finished, container apps will scale down the application back to 3 replicas.

### Accessing the Application
The URL to the deployed application can be fond in the logs in GitHub actions, or in azure portal. Copy the URL and paste it in to a browser to see the result.

## File Structure
```bash
.
├── lab.bicep           # Bicep file that declares a Container App in Azure
├── load.js             # K6 script for load testing
└── README.md           # Project documentation
```
