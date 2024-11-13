// Parameters
@description('Location for the Container App.')
param location string = 'swedencentral'

@description('Unique name for the Container App.')
param containerAppName string = 'my-scalingcloud-app'

@description('Application Container Image')
param applicationImage string = 'danielfroding/scalingcloud'

@description('Unique name for the Front Door profile.')
param frontDoorProfileName string = 'MyFrontDoorProfile'

@description('Unique name for the Front Door endpoint.')
param frontDoorEndpointName string = 'afd-${uniqueString(resourceGroup().id)}'

@description('SKU name for the Front Door profile.')
param frontDoorSkuName string = 'Standard_AzureFrontDoor'

@description('Minimum number of replicas')
param minReplicas int = 3 // Increased to start with 3 containers

@description('Maximum number of replicas')
param maxReplicas int = 20 

// Variables for names
var frontDoorOriginGroupName = 'MyOriginGroup'
var frontDoorOriginName = 'MyAppOrigin'
var frontDoorRouteName = 'MyRoute'

// Container App Environment
resource containerAppEnv 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: 'myContainerAppEnv'
  location: location
  properties: {}
}

// Container App
resource applicationContainerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      ingress: {
        external: true
        targetPort: 80
        transport: 'auto'
      }
    }
    template: {
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
        rules: [
          {
            name: 'http-requests-scaling'
            custom: {
              type: 'http'
              metadata: {
                concurrentRequests: string(50)
              }
            }
          }
        ]
      }
      containers: [
        {
          name: 'application'
          image: applicationImage
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
        }
      ]
    }
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
    hostName: applicationContainerApp.properties.configuration.ingress.fqdn
    httpPort: 80
    originHostHeader: applicationContainerApp.properties.configuration.ingress.fqdn
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
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'HttpOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Disabled'
  }
}

// Outputs
output containerAppFqdn string = applicationContainerApp.properties.configuration.ingress.fqdn
output frontDoorEndpointHostName string = frontDoorEndpoint.properties.hostName
