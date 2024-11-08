# Lab 2 - Nginx Reverse Proxy with Docker and Docker Compose

This lab demonstrates how to set up an Nginx reverse proxy in a Docker container to serve static content from another container using Docker Compose. The setup uses an Nginx configuration file to forward requests to a backend web server and includes instructions for load testing to observe the behavior of load balancing.

## Contents

- **docker-compose.yml**: Defines the services and configuration for the Nginx and backend containers.
- **nginx.conf**: Nginx configuration file for setting up the reverse proxy.
- **load.js**: K6 script for load testing the Nginx load balancer.

## Getting Started

### Prerequisites

- [Docker](https://www.docker.com/) and [Docker Compose](https://docs.docker.com/compose/) must be installed on your machine. If not, go to the links and install them.
- [K6](https://k6.io/) must be installed for running load tests. Follow the instructions on the K6 website to install it.


### Setup

1. Create a custom Docker image named `my-website` using your existing Docker setup for serving static content. Refer to Lab 1 if you need guidance on building the image:

   ```bash
   docker build -t my-website .

2. Start the services using Docker Compose by executing this command in the project directory:

   ```bash
   docker compose up -d --scale my-website=3

This command starts both the nginx service and the my-website service. The Nginx container listens on port 8080 and forwards requests to the backend web server.

Accessing the Application

Open your browser and go to http://localhost:8080 to view the content served through the Nginx reverse proxy.

### Running the Load Test
1. Run a load test using the following command:
    ```bash
    k6 run loadtest.js

This command will simulate 100 virtual users sending requests to the Nginx server over a duration of 10 seconds.

### Analyzing the Results

* Check Response Status: The K6 script will check if the responses have a status code of 200, indicating successful requests.
* Monitor Performance: Observe how the Nginx load balancer handles the load and distributes traffic among the 3 backend instances.
* Adjust Parameters: You can modify the number of virtual users (vus) and the duration of the test (duration) to simulate different traffic patterns and evaluate the performance under varying loads.
* Changing the Number of Backend Instances by adjusting the --scale Flag
When starting your Docker Compose setup, use the --scale flag to specify the desired number of instances for my-website. For example, if you want to run 10 instances instead of 3, you would use:
   ```bash
   docker compose up -d --scale my-website=10

This command can be given even when the application is running. Docker will start 7 additional containers on the fly. Test it and run the load test again to se if the performance changes.

File Structure
```bash
.
├── docker-compose.yml  # Docker Compose configuration for Nginx and the backend
├── nginx.conf          # Nginx configuration for reverse proxying to the backend
├── load.js             # K6 script for load testing
└── README.md           # Project documentation