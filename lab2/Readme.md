# Lab 2 - Nginx Reverse Proxy with Docker and Docker Compose

This lab demonstrates how to set up an Nginx reverse proxy in a Docker container to serve static content from another container using Docker Compose. The setup uses an Nginx configuration file to forward requests to a backend web server and includes instructions for load testing to observe the behavior of load balancing.

**AKF Connection (X-Axis)**: This lab provides a local demonstration of **Horizontal Duplication**. By using Docker Compose to run multiple instances (replicas) of our web server and placing a Load Balancer (Nginx) in front of them, we are implementing X-Axis scaling. This allows us to handle more simulated load by verifying that requests are distributed across the available instances.

## Contents

- **docker-compose.yml**: Defines the services and configuration for the Nginx and backend containers.
- **nginx.conf**: Nginx configuration file for setting up the reverse proxy.
- **load.js**: K6 script for load testing the Nginx load balancer.

### Prerequisites
- [K6](https://k6.io/) must be installed for running load tests. Follow the instructions on the K6 website to install it.
- **Stop Lab 1**: Ensure you have stopped the container from Lab 1 (`docker stop <container-id>` or `docker rm -f <container-id>`) to free up port **8080**.

### Fallback: Using Podman
If you are using **Podman**:
1.  You need **podman-compose**. Install it (usually via Python): `pip install podman-compose` or `sudo apt-get install podman-compose`.
2.  Replace `docker compose` with `podman-compose`.
    *   Start: `podman-compose up -d --scale my-website=3`
    *   Stop: `podman-compose down`

### Execution

1. Create a custom Docker image named `my-website` using your existing Docker setup for serving static content. 
   
   **Important:** You must build this image manually if you haven't already (or if you are in a fresh Codespace), because `docker-compose.yml` expects it to exist locally.
   ```bash
   cd ../lab1
   docker build -t my-website .
   cd ../lab2
   ```

2. Start the services using Docker Compose by executing this command in the project directory:

   ```bash
   docker compose up -d --scale my-website=3

This command starts both the nginx service and three instances of the my-website container. The Nginx container listens on port 8080 and forwards requests to the backend web server.

### Accessing the Application

Open your browser and go to http://localhost:8080 to view the content served through the Nginx reverse proxy.

### Running the Load Test
1. Run a load test using the following command:
    ```bash
    k6 run load.js
    ```

This command will simulate 100 virtual users sending requests to the Nginx server over a duration of 10 seconds.

### Analyzing the Results

* Check Response Status: The K6 script will check if the responses have a status code of 200, indicating successful requests.
* Monitor Performance: Observe how the Nginx load balancer handles the load and distributes traffic among the 3 backend instances.
* Adjust Parameters: You can modify the number of virtual users (vus) and the duration of the test (duration) to simulate different traffic patterns and evaluate the performance under varying loads.
* Changing the Number of Backend Instances by adjusting the --scale Flag
When starting your Docker Compose setup, use the --scale flag to specify the desired number of instances for my-website. For example, if you want to run 10 instances instead of 3, you would use:
   ```bash
   docker compose scale my-website=10
   ```
Docker will start 7 additional containers on the fly. Test it and run the load test again to se if the performance changes.

### Acceptance Criteria
*   The website is accessible at `http://localhost:8080`.
*   Load tests run via K6 exit successfully (exit code 0 / no major errors).
*   Requests are load balanced across the replicas.

### Shutdown Instructions
To stop and remove all containers and networks created by Docker Compose:
```bash
docker compose down
```


### File Structure
```bash
.
├── docker-compose.yml  # Docker Compose configuration for Nginx and the backend
├── nginx.conf          # Nginx configuration for reverse proxying to the backend
├── load.js             # K6 script for load testing
└── README.md           # Project documentation