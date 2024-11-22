@description('Location for the Container App Environment.')
param location string = 'swedencentral'

@description('Application Container Image.')
param applicationImage string = 'danielfroding/scalingcloud'

@description('Unique name for the Front Door endpoint.')
param frontDoorEndpointName string = 'afd-${uniqueString(resourceGroup().id)}'

// Create a Container App Environment
resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: 'appEnvironment'
  location: location
  properties: {}
}

// Deploy the Application Container as a Container App with public ingress
resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'my-website'
  location: location
  properties: {
    managedEnvironmentId: containerAppEnvironment.id
    configuration: {
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
resource x§ 'Microsoft.Cdn/profiles/originGroups/origins@2021-06-01' = {
  name: 'MyAppOrigin'
  parent: frontDoorOriginGroup
  properties: {
    hostName: containerApp.properties.configuration.ingress.fqdn
    httpPort: 80
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
