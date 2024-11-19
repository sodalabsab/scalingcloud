# Lab 1 - A simple container in Docker Setup
This directory contains a simple Docker setup with an Nginx server, that serves static files from a specified directory. A scrip will fill that directory with content from html5up and a website framework called massively.

## Contents

- **Dockerfile**: Defines the Nginx container configuration.
- **setup-massively.sh**: Script to dowload and extract [massively](https://html5up.net/massively) to a html directory that acts as web content for the webserver.
- **setup-massively.bat**: Same script for windows


### Prerequisites

- Complete Setup 1 in the readme-file at the root of the repo.

### Execution

1.	Download and setup the massively web-framework by running the script:

      ```bash
      ./setup-massively.sh
2.	Build a Docker image and give it a name by executing this command:
      ```bash
      docker build -t my-website .
3.	Start a new container using the image:
      ```bash
      docker run -d -p 8080:80 my-website
      
This command maps port 8080 on your host machine to port 80 in the container, where Nginx is listening and serving the content in the html directory.

### Accessing the Application

Open your browser and go to http://localhost:8080 to view the served static files.

### File Structure
```bash
      .
      ├── Dockerfile         # Dockerfile to set up the Nginx container
      ├── README.md          # Project documentation
      └── setup-massively.sh # Script that creates a directory for static HTML files to be served
