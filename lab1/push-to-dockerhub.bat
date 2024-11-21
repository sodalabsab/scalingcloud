@echo off

:: Variables
set USERNAME=danielfroding
set REPOSITORY=my-website
set TAG=latest

:: Build the image
echo Building Docker image...
docker build --platform linux/amd64 -t %USERNAME%/%REPOSITORY%:%TAG% .

:: Log in to DockerHub
echo Logging in to DockerHub...
docker login
if errorlevel 1 (
    echo Docker login failed. Exiting...
    exit /b 1
)

:: Push the image
echo Pushing Docker image to DockerHub...
docker push %USERNAME%/%REPOSITORY%:%TAG%
if errorlevel 1 (
    echo Docker push failed. Exiting...
    exit /b 1
)

echo Docker image pushed to DockerHub: %USERNAME%/%REPOSITORY%:%TAG%