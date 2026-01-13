# Lab 3 - Deploying a Container App to Azure with Bicep

This lab demonstrates deploying a simple Container App to Azure using Bicep and automating the deployment with GitHub Actions. 

**AKF Connection (X-Axis)**: This lab focuses on **Horizontal Duplication**. By deploying our container to Azure Container Apps, we can easily run multiple identical copies (replicas) of our application. The platform handles the load balancing between them, adhering to the X-Axis scaling principle.

The Bicep file uses a declarative syntax to define Azure resources, allowing for consistent, repeatable deployments while treating your infrastructure as code.

## Contents

- **lab.bicep** A Bicep file that declares a Container App in Azure.
- **load.js**: K6 script for load testing the containerApp.

### Prerequisites
- Setup 2 from the readme at the root of to reposiroty must have been done and verified
- [K6](https://k6.io/) must be installed for running load tests. Follow the instructions on the K6 website to install it.
- **Completed Lab 1**: You need the source code and knowledge from Lab 1.

### Step 1: Push the Image to Azure (ACR)
Before we can deploy the container app in Azure, we need to make our container image available in the cloud. We will push the image we built in Lab 1 to the Azure Container Registry (ACR) we configured in Setup 2.

1.  **Login to Azure**:
    ```bash
    az login
    ```

2.  **Login to your ACR**:
    *Replace `<acr-name>` with the name of your registry.*
    ```bash
    az acr login --name <acr-name>
    ```

3.  **Build and Push the Image**:
    Navigate to the `lab1` directory (where the Dockerfile is) and run the provided helper script. It handles building (for amd64), tagging, and pushing.
    
    **Linux/Mac:**
    *Open the script `push-to-acr.sh` and update the `ACR_NAME` variable first!*
    ```bash
    cd lab1
    ./push-to-acr.sh
    cd ..
    ```
    
    **Windows:**
    *Open the script `push-to-acr.bat` and update the `ACR_NAME` variable first!*
    ```cmd
    cd lab1
    push-to-acr.bat
    cd ..
    ```

    *Alternatively, you can run the docker commands manually as described in the `push-to-acr.sh` file.*

4.  **Verify**: check the Azure Portal -> Container Registry -> Repositories. You should see `my-website` with the tag `latest`.

### Step 2: Deploy Infrastructure (Bicep)
1. Go to the "action" tab in your GitHub account and select the `Lab bicep deployment` workflow to the left
2. Click on the "Run workflow" button and specify `lab3` Lab nr (That is the default)
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

9. (Optional): Figure out how to access one of the replicas and login to it. Try to manipulate the index.html file in the container so that the front page shows some other text. Tip: There is no editor in the nginx image, use `sed`instead. Example:
```bash
sed -i 's/\b[Mm][Aa][Ss][Ss][Ii][Vv][Ee][Ll][Yy]\b/Smallish/gI' index.html
```

### Accessing the Application
### Acceptance Criteria
*   The application is accessible via the public URL provided by Azure Container Apps.
*   The K6 load test triggers auto-scaling, increasing the replica count from 3 to a higher number (up to 20).
*   After the load test finishes, the replica count eventually scales back down.

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
