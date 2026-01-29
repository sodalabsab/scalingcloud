@echo off
setlocal EnableDelayedExpansion

:: --- 1. Load Configuration from ../config.env ---
set "CONFIG_PATH=../config.env"

if exist "%CONFIG_PATH%" (
    echo [INFO] Loading configuration from %CONFIG_PATH%
    for /f "usebackq tokens=1* delims==" %%A in ("%CONFIG_PATH%") do (
        set "KEY=%%A"
        set "VALUE=%%B"
        :: Remove potential quotes or whitespace if needed, simplified here
        set "!KEY!=!VALUE!"
    )
) else (
    echo [ERROR] Could not find config.env at %CONFIG_PATH%
    echo         Make sure you are running this script from the 'lab3' folder.
    exit /b 1
)

:: --- 2. Local Variables (Specific to this image) ---
set "REPOSITORY=my-website"
set "TAG=latest"

:: --- 3. Build the image ---
echo --- 🐳 Building Docker Image ---
echo     Registry: %ACR_NAME%
echo     Image:    %REPOSITORY%:%TAG%

docker build --platform linux/amd64 -t %ACR_NAME%.azurecr.io/%REPOSITORY%:%TAG% ../lab1

:: --- 4. Log in to ACR ---
echo --- 🔑 Logging in to ACR (%ACR_NAME%) ---
call az acr login --resource-group %RG_NAME% --name %ACR_NAME%
if errorlevel 1 (
    echo ACR login failed. Exiting...
    exit /b 1
)

:: --- 5. Push the image ---
echo --- 🚀 Pushing Image ---
docker push %ACR_NAME%.azurecr.io/%REPOSITORY%:%TAG%
if errorlevel 1 (
    echo Docker push failed. Exiting...
    exit /b 1
)

:: Update GitHub Variable (Optional for local script, but good for consistency)
call gh variable set ACR_IMAGE --body "%ACR_NAME%.azurecr.io/%REPOSITORY%:%TAG%" --repo "%GH_ORG%/%GH_REPO%"

echo ✅ Success! Image pushed to: %ACR_NAME%.azurecr.io/%REPOSITORY%:%TAG%
