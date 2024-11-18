@description('Location for the Container App Environment.')
param location string = 'swedencentral'

@description('Name of the Container App Environment.')
param environmentName string = 'appEnvironment'

@description('Application Container Image.')
param applicationImage string = 'danielfroding/scalingcloud'

@description('Port for the Application.')
param applicationPort int = 80

@description('Minimum number of replicas.')
param minReplicas int = 3 // Increased to start with 3 containers

@description('Maximum number of replicas.')
param maxReplicas int = 20 // Allow scaling up to 20 containers

@description('Target average number of requests per second per replica.')
param targetRequests int = 50

@description('Unique name for the Front Door profile.')
param frontDoorProfileName string = 'MyFrontDoorProfile'

@description('Unique name for the Front Door endpoint.')
param frontDoorEndpointName string = 'afd-${uniqueString(resourceGroup().id)}'

@description('SKU name for the Front Door profile.')
param frontDoorSkuName string = 'Standard_AzureFrontDoor'

// Variables for names
var frontDoorOriginGroupName = 'MyOriginGroup'
var frontDoorOriginName = 'MyAppOrigin'
var frontDoorRouteName = 'MyRoute'

// Create a Container App Environment
resource containerAppEnv 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: environmentName
  location: location
  properties: {}
}

// Deploy the Application Container as a Container App with public ingress
resource applicationContainerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'application'
  location: location
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      ingress: {
        external: true
        targetPort: applicationPort
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
                concurrentRequests: string(targetRequests)
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
    httpPort: applicationPort
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
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'HttpsOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
  }
}

// Outputs
output applicationUrl string = 'https://${applicationContainerApp.properties.configuration.ingress.fqdn}'
output frontDoorEndpointHostName string = frontDoorEndpoint.properties.hostName
