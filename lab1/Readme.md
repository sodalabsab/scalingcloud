# Lab 1 - Introduction to Docker

This lab introduces the fundamentals of containerization using Docker. You will learn how to build a Docker image that serves a simple website using an Nginx server, and run it locally.

## Contents

- **`Dockerfile`**: The blueprint for your container. It defines the base image (Nginx) and the commands to assemble your application.
- **`setup-massively.sh` / `setup-massively.bat`**: A helper script that downloads a website template ([Massively](https://html5up.net/massively)) and places it into an `html` directory. This directory will be served by your Nginx container.

## Prerequisites

Before starting, ensure you have completed **Setup 1** in the [root README](../README.md). Specifically, you need:
1.  **Docker Desktop** installed and running.

### Fallback: Using Podman
If you cannot run Docker Desktop (e.g., due to admin restrictions) but have WSL 2 enabled, you can use **Podman**:
1.  **Install Podman**: inside your WSL 2 distro (e.g., Ubuntu):
    ```bash
    sudo apt-get update && sudo apt-get install -y podman
    ```
2.  **Run Commands**: simply replace `docker` with `podman` in all instructions.
    *   Build: `podman build -t my-website .`
    *   Run: `podman run -d -p 8080:80 my-website`
    *   *Note: Rootless Podman can behave slightly differently, but for this lab, it is a drop-in replacement.*

---

## Part 1: Local Development

In this section, you will build and run the container locally on your machine to verify it works.

### 1. Prepare the Content
First, we need some web content to serve. Run the setup script to download the "Massively" website template:

**Mac/Linux:**
```bash
chmod +x setup-massively.sh
./setup-massively.sh
```

**Windows:**
```cmd
setup-massively.bat
```

*This creates an `html` folder in your current directory containing the website files.*

### 2. Build the Docker Image
Now, use the `docker build` command to create an image named `my-website` from the `Dockerfile` in the current directory (`.`):

```bash
docker build -t my-website .
```

*The `-t` flag tags the image with a name so you can easily refer to it later.*

### 3. Run the Container
Start a container instance from your new image. We map port **8080** on your machine to port **80** inside the container (where Nginx listens):

```bash
docker run -d -p 8080:80 my-website
```

*   `-d`: Runs the container in "detached" mode (in the background).
*   `-p 8080:80`: Maps localhost:8080 -> container:80.

### 4. Verify
Open your web browser and navigate to [http://localhost:8080](http://localhost:8080). You should see the "Massively" website running.

---

## Part 2: Hands-on with Docker Desktop

Now that your container is running, let's explore it using the Docker Desktop GUI. This is very helpful for debugging and understanding what's happening inside.

### Exercise 1: Finding Container Logs
1.  Open **Docker Desktop Dashboard**.
2.  Go to the **Containers** tab.
3.  Click on your running container (it might have a random name if you didn't specify one, or look for `my-website`).
4.  Click on the **Logs** tab.
    *   *Observation:* You should see Nginx access logs. Try refreshing your browser window at `localhost:8080` and watch new log entries appear instantly!

### Exercise 2: Executing Commands (The Shell)
Sometimes you need to look inside a container to debug files or configuration.
1.  In Docker Desktop, while viewing your container, click on the **Exec** or **Terminal** tab.
2.  This opens a command shell *inside* the Linux container.
3.  Type `ls -l` to see the files.
4.  Navigate to the web content:
    ```bash
    cd /usr/share/nginx/html
    ls
    ```
    *You should see the index.html and assets for the website.*

### Exercise 3: "Hacking" the Container
Let's modify the running website live. Note that containers are usually "immutable" (changes are lost when restarted), but this demonstrates how to test changes quickly.

1.  In the Container Terminal (from Exercise 2), we will edit the `index.html`.
2.  Since this container is minimal, it doesn't have editors like `nano` or `vi`. We will use `sed` (Stream Editor) to search and replace text.
3.  Run this command to change the main title "Massively" to "Hacked!":
    ```bash
    sed -i 's/Massively/Hacked!/g' index.html
    ```
4.  Go back to your browser and **Refresh** the page.
    *   *Result:* The big title should now say **Hacked!**.

---

### Acceptance Criteria
*   You can access the website at `http://localhost:8080`.
*   The website displays the "Massively" template correctly.

### Shutdown Instructions
To stop and remove the running container:
1.  Find the container ID: `docker ps`
2.  Stop the container: `docker stop <container-id>`
3.  (Optional) Remove the container: `docker rm <container-id>`



## Next Steps

Now that you have successfully containerized the application and confirmed it works locally, you are ready to explore Docker Compose (Lab 2) or move to the cloud (Lab 3).

### File Structure Refrence
```text
.
├── Dockerfile          # Configuration for the Nginx container
├── README.md           # This documentation
├── push-to-acr.sh      # Helper script for pushing to Azure (Used in Lab 3)
├── setup-massively.sh  # Content setup script (Linux/Mac)
└── setup-massively.bat # Content setup script (Windows)
```
# Test build trigger
