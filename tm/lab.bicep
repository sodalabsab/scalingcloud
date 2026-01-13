@description('Primary location for the resources.')
param primaryLocation string = 'swedencentral'

@description('Secondary location for the resources.')
param secondaryLocation string = 'westeurope'

@description('Container image for the web app from Azure Container Registry (ACR).')
param containerImage string = 'DOCKER|<acr-name>.azurecr.io/scalingcloud:latest'

@description('Name of the Traffic Manager profile.')
param trafficManagerName string = 'myUniqueTrafficManagerProfile123'

// App Service Plans
resource primaryAppServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: 'myPrimaryAppServicePlan'
  location: primaryLocation
  sku: {
    tier: 'Standard'
    name: 'S1'
  }
  properties: {
    reserved: true // Indicates it's for Linux
  }
}

resource secondaryAppServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: 'mySecondaryAppServicePlan'
  location: secondaryLocation
  sku: {
    tier: 'Standard'
    name: 'S1'
  }
  properties: {
    reserved: true // Indicates it's for Linux
  }
}

// Web Apps
resource primaryWebApp 'Microsoft.Web/sites@2022-09-01' = {
  name: 'my-website-primary'
  location: primaryLocation
  properties: {
    serverFarmId: primaryAppServicePlan.id
    siteConfig: {
      linuxFxVersion: containerImage
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'DOCKER_ENABLE_CI'
          value: 'true'
        }
      ]
    }
    httpsOnly: true
  }
}

resource secondaryWebApp 'Microsoft.Web/sites@2022-09-01' = {
  name: 'my-website-secondary'
  location: secondaryLocation
  properties: {
    serverFarmId: secondaryAppServicePlan.id
    siteConfig: {
      linuxFxVersion: containerImage
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'DOCKER_ENABLE_CI'
          value: 'true'
        }
      ]
    }
    httpsOnly: true
  }
}

// Traffic Manager Profile
resource trafficManager 'Microsoft.Network/trafficManagerProfiles@2022-04-01' = {
  name: trafficManagerName
  location: 'global'
  properties: {
    profileStatus: 'Enabled'
    trafficRoutingMethod: 'Performance'
    dnsConfig: {
      relativeName: trafficManagerName
      ttl: 30
    }
    monitorConfig: {
      protocol: 'HTTP'
      port: 80
      path: '/'
    }
    endpoints: [
      {
        name: 'primaryEndpoint'
        type: 'Microsoft.Network/trafficManagerProfiles/AzureEndpoints'
        properties: {
          targetResourceId: primaryWebApp.id
          endpointStatus: 'Enabled'
        }
      }
      {
        name: 'secondaryEndpoint'
        type: 'Microsoft.Network/trafficManagerProfiles/AzureEndpoints'
        properties: {
          targetResourceId: secondaryWebApp.id
          endpointStatus: 'Enabled'
        }
      }
    ]
  }
}
