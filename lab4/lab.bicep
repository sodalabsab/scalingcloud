@description('Location for the Container App Environment.')
param location string = resourceGroup().location

@description('Application Container Image.')
param applicationImage string

@description('The ACR Login Server (e.g. sodalabs001.azurecr.io)')
param acrServer string

@description('The Resource ID of the User Assigned Identity used to pull images')
param userAssignedIdentityId string

@description('Unique name for the Front Door endpoint.')
param frontDoorEndpointName string = 'afd-${uniqueString(resourceGroup().id)}'

@description('The Name of the Container App')
param containerAppName string = 'my-website'

var environmentName = 'appEnvironment'

// Create a Container App Environment
resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: environmentName
  scope: resourceGroup()
  properties: {
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
  }
}

// Deploy the Application Container as a Container App with public ingress
resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppName
  scope: resourceGroup()
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppEnvironment.id
    configuration: {
      registries: [
        {
          server: acrServer
          identity: userAssignedIdentityId
        }
      ]
      ingress: {
        external: true
        targetPort: 80
        transport: 'auto'
      }
    }
    template: {
      scale: {
        minReplicas: 3
        maxReplicas: 20
        rules: [
          {
            name: 'http-requests-scaling'
            custom: {
              type: 'http'
              metadata: {
                concurrentRequests: string(20)
              }
            }
          }
        ]
      }
      containers: [
        {
          name: 'my-website'
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
  name: 'MyFrontDoorProfile'
  location: 'global'
  sku: {
    name: 'Standard_AzureFrontDoor'
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
  name: 'MyOriginGroup'
  parent: frontDoorProfile
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 2
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Https' // Changed from Http to Https to avoid 301 Redirects from ACA
      probeIntervalInSeconds: 10
    }
  }
}

// Front Door Origin
resource frontDoorOrigin 'Microsoft.Cdn/profiles/originGroups/origins@2021-06-01' = {
  name: 'MyAppOrigin'
  parent: frontDoorOriginGroup
  properties: {
    hostName: containerApp.properties.configuration.ingress.fqdn
    httpPort: 80
    httpsPort: 443 // Explicitly defined to ensure HttpsOnly forwarding works
    originHostHeader: containerApp.properties.configuration.ingress.fqdn
    priority: 1
    weight: 1000
  }
}

// Front Door Route
resource frontDoorRoute 'Microsoft.Cdn/profiles/afdEndpoints/routes@2021-06-01' = {
  name: 'MyRoute'
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
output applicationUrl string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output frontDoorEndpointHostName string = frontDoorEndpoint.properties.hostName
