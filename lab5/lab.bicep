// Parameters
@description('Location for the App Service.')
param location string = 'swedencentral'

@description('Unique name for the App Service.')
param appServiceName string = 'my-scalingcloud-app'

@description('App Service Plan Name')
param appServicePlanName string = 'myAppServicePlan'

@description('Unique name for the Front Door profile.')
param frontDoorProfileName string = 'MyFrontDoorProfile'

@description('Container image for the web app from Azure Container Registry (ACR).')
param containerImage string = 'DOCKER|danielfroding/scalingcloud'

@description('Unique name for the Front Door endpoint.')
param frontDoorEndpointName string = 'afd-${uniqueString(resourceGroup().id)}'

@description('SKU name for the Front Door profile.')
param frontDoorSkuName string = 'Standard_AzureFrontDoor'

// Variables for names
var frontDoorOriginGroupName = 'MyOriginGroup'
var frontDoorOriginName = 'MyAppOrigin'
var frontDoorRouteName = 'MyRoute'

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'B1' // Adjust the SKU as needed (e.g., B1 for Basic, S1 for Standard)
    tier: 'Basic'
  }
  properties: {
    reserved: true // Set to true for Linux-based App Service
  }
}

// App Service
resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: appServiceName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'WEBSITES_PORT'
          value: '80' // Required for containerized app to listen on port 80
        }
      ]
      linuxFxVersion: containerImage // Using Docker image from Docker Hub
    }
    httpsOnly: true
  }
}

// Front Door Profile
resource frontDoorProfile 'Microsoft.Cdn/profiles@2021-06-01' = {
  name: frontDoorProfileName
  location: 'global'
  sku: {
    name: frontDoorSkuName
  }
}

// Front Door Endpoint
resource frontDoorEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2021-06-01' = {
  name: frontDoorEndpointName
  parent: frontDoorProfile
  location: 'global'
  properties: {
    enabledState: 'Enabled'
  }
}

// Front Door Origin Group
resource frontDoorOriginGroup 'Microsoft.Cdn/profiles/originGroups@2021-06-01' = {
  name: frontDoorOriginGroupName
  parent: frontDoorProfile
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Http'
      probeIntervalInSeconds: 120
    }
  }
}

// Front Door Origin
resource frontDoorOrigin 'Microsoft.Cdn/profiles/originGroups/origins@2021-06-01' = {
  name: frontDoorOriginName
  parent: frontDoorOriginGroup
  properties: {
    hostName: appService.properties.defaultHostName
    httpPort: 80
    originHostHeader: appService.properties.defaultHostName
    priority: 1
    weight: 1000
  }
}

// Front Door Route
resource frontDoorRoute 'Microsoft.Cdn/profiles/afdEndpoints/routes@2021-06-01' = {
  name: frontDoorRouteName
  parent: frontDoorEndpoint
  dependsOn: [
    frontDoorOrigin
  ]
  properties: {
    originGroup: {
      id: frontDoorOriginGroup.id
    }
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'HttpsOnly'
    linkToDefaultDomain: 'Disabled'
    httpsRedirect: 'Enabled'
  }
}

// Outputs
output appServiceFqdn string = appService.properties.defaultHostName
output frontDoorEndpointHostName string = frontDoorEndpoint.properties.hostName
