@echo off

REM Define the URL for the Massively template and target directory
set "TEMPLATE_URL=https://html5up.net/massively/download"
set "TARGET_DIR=html"

REM Download the Massively template
echo Downloading HTML5 UP Massively template...
curl -L -o massively.zip %TEMPLATE_URL%

REM Create the target directory if it doesn't exist
echo Creating target directory: %TARGET_DIR%
if not exist %TARGET_DIR% (
    mkdir %TARGET_DIR%
)

REM Extract the template into the target directory
echo Extracting template into %TARGET_DIR%
tar -xf massively.zip -C %TARGET_DIR%

REM Clean up the downloaded zip file
echo Cleaning up...
del massively.zip

echo Setup complete. Massively template is ready in the %TARGET_DIR% directory.