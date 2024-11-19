#!/bin/bash

# Define the URL for the Massively template and target directory
TEMPLATE_URL="https://html5up.net/massively/download"
TARGET_DIR="html"
 
# Download the Massively template
echo "Downloading HTML5 UP Massively template..."
curl -L -o massively.zip "$TEMPLATE_URL"

# Create the target directory if it doesn't exist
echo "Creating target directory: $TARGET_DIR"
mkdir -p "$TARGET_DIR"

# Extract the template into the target directory
echo "Extracting template into $TARGET_DIR"
unzip massively.zip -d "$TARGET_DIR"

# Clean up the downloaded zip file
echo "Cleaning up..."
rm massively.zip

echo "Setup complete. Massively template is ready in the $TARGET_DIR directory."