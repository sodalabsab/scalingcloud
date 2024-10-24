@description('Location for all resources.')
param location string = 'swedencentral'

@description('Name of the App Service Plan.')
param appServicePlanName string = 'containerAppServicePlan'

@description('Name of the web app.')
param webAppName string = 'myContainerApp'

@description('Container image to deploy.')
param containerImage string = 'myregistry.azurecr.io/mycontainerimage:latest'

@description('App Service Plan SKU')
param sku string = 'B1' // Adjust based on your needs, here I used a basic tier

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  sku: {
    tier: 'Basic'
    name: sku
    capacity: 1
  }
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://myregistry.azurecr.io' // Replace with your container registry URL
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: '<your-username>' // Replace with your container registry username
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: '<your-password>' // Replace with your container registry password
        }
      ]
      linuxFxVersion: 'DOCKER|${containerImage}' // Use container image
    }
  }
}
