# Azure Scaling Lab: Exercises

This lab guides you through the concepts of scaling, from local development to advanced cloud patterns.

## 🛠️ Setup & Prerequisites

Before starting the exercises, ensure you have:
1.  **Repository Cloned**: `git clone ...`
2.  **Tools Installed**: Docker, Azure CLI, GitHub CLI, k6.
    *   *Install k6*: `brew install k6` or check [k6.io](https://k6.io/docs/get-started/installation/)

---

## Exercise 1: Local Development & Scaling

**Goal**: Understand balancing traffic across multiple containers using Docker Compose.

1.  **Run the Stack**:
    Start one instance of the app behind an Nginx load balancer.
    ```bash
    docker-compose up -d
    ```
    Open [http://localhost:8080](http://localhost:8080). You should see the "Hello World" app.

2.  **Scale it Up**:
    Scale the application to 3 instances. Nginx will automatically round-robin requests between them (handled by Docker's internal DNS).
    ```bash
    docker-compose up -d --scale app=3
    ```

3.  **Load Test**:
    Use `k6` to send traffic to your local cluster.
    ```bash
    k6 run load-tests/script.js
    ```
    *Observe*: Docker Desktop stats or logs (`docker-compose logs -f app`) to see traffic hitting different containers.

4.  **Cleanup**:
    ```bash
    docker-compose down
    ```

---

## Exercise 2: Cloud Platform Foundation

**Goal**: Provision the Azure "Landing Zone" for your applications.

1.  **Run Setup Script**:
    ```bash
    ./setup.sh
    ```
    This creates the Resource Group, Container Registry (ACR), and Container App Environment.

2.  **Verify**:
    Log in to the [Azure Portal](https://portal.azure.com) and find your resource group (`rg-aca-platform`).

---

## Exercise 3: Deployment & Vertical Scaling

**Goal**: Deploy your app and understand "Vertical Scaling" (adding more power to a single instance).

1.  **Configure CI/CD**:
    Run the GitHub setup to connect your repo and secrets.
    ```bash
    ./github_setup.sh
    ```
    *Wait for the GitHub Action to complete and verify the app is running in Azure.*

2.  **Vertical Scale**:
    Modify `infra/app/main.bicep`. Change the CPU and Memory allocation:
    ```bicep
    resources: {
        cpu: json('1.0')   // Was 0.5
        memory: '2.0Gi'    // Was 1.0Gi
    }
    ```

3.  **Deploy Change**:
    Commit and push the change.
    ```bash
    git add .
    git commit -m "Vertical scale up"
    git push
    ```

4.  **Verify**:
    Check the Azure Portal > Container App > Revisions. You should see a new revision with higher resources.

---

## Exercise 4: Horizontal Autoscaling (KEDA)

**Goal**: Configure the app to automatically add more instances (replicas) when traffic spikes.

1.  **Configure Autoscaling**:
    Open `infra/app/main.bicep`. Update the `scale` block parameters:
    *   `minReplicas`: 1
    *   `maxReplicas`: 10

    *Note: The template is already pre-configured with a KEDA HTTP scaling rule (`concurrentRequests: '10'`).*

2.  **Deploy**:
    Commit and push your changes to enable autoscaling.

3.  **Stress Test**:
    Run `k6` against your **Azure URL**.
    ```bash
    # Get your App URL from the Azure Portal or setup output
    export BASE_URL="https://aca-hello-world.....azurecontainerapps.io"
    
    k6 run -e BASE_URL=$BASE_URL load-tests/script.js
    ```

4.  **Observe**:
    Go to the Azure Portal > Container App > **Metrics**.
    View the **Replica Count**. You should see it increase as the load test runs and scale back down when it finishes.
