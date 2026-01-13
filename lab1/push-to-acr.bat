@echo off

:: Variables
set ACR_NAME=<your-acr-name>
set REPOSITORY=my-website
set TAG=latest

:: Build the image
echo Building Docker image...
docker build --platform linux/amd64 -t %ACR_NAME%.azurecr.io/%REPOSITORY%:%TAG% .

:: Log in to ACR
echo Logging in to ACR...
call az acr login --name %ACR_NAME%
if errorlevel 1 (
    echo ACR login failed. Exiting...
    exit /b 1
)

:: Push the image
echo Pushing Docker image to ACR...
docker push %ACR_NAME%.azurecr.io/%REPOSITORY%:%TAG%
if errorlevel 1 (
    echo Docker push failed. Exiting...
    exit /b 1
)

echo Docker image pushed to ACR: %ACR_NAME%.azurecr.io/%REPOSITORY%:%TAG%
