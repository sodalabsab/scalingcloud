#!/bin/bash
set -e # Stop on error

# --- 1. Load Configuration from ../infra/config.env ---
CONFIG_PATH="../config.env"

if [ -f "$CONFIG_PATH" ]; then
    echo "✅ Loading configuration from $CONFIG_PATH..."
    source "$CONFIG_PATH"
else
    echo "❌ Error: Could not find config.env at $CONFIG_PATH"
    echo "   Make sure you are running this script from the 'lab3' folder."
    exit 1
fi

# --- 2. Local Variables (Specific to this image) ---
# We keep these here because config.env handles Infrastructure, 
# while this script handles a specific Application artifact.
REPOSITORY="my-website"
TAG="latest"

# Note: RG_NAME and ACR_NAME are now loaded from config.env automatically

# --- 3. Build the image ---
echo "--- 🐳 Building Docker Image ---"
echo "    Registry: $ACR_NAME"
echo "    Image:    $REPOSITORY:$TAG"

# We use the variables loaded from the config file
docker build --platform linux/amd64 -t "$ACR_NAME.azurecr.io/$REPOSITORY:$TAG" .

# --- 4. Log in to ACR ---
echo "--- 🔑 Logging in to ACR ($ACR_NAME) ---"
az acr login --resource-group "$RG_NAME" --name "$ACR_NAME"

# --- 5. Push the image ---
echo "--- 🚀 Pushing Image ---"
docker push "$ACR_NAME.azurecr.io/$REPOSITORY:$TAG"
gh variable set ACR_IMAGE --body "$ACR_NAME.azurecr.io/$REPOSITORY:$TAG" --repo "$GH_ORG/$GH_REPO"


echo "✅ Success! Image pushed to: $ACR_NAME.azurecr.io/$REPOSITORY:$TAG"