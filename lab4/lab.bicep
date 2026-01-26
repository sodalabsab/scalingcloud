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

// Create a Log Analytics Workspace for Access Logs
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: 'la-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Create a Container App Environment
resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: environmentName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
  }
}

// Deploy the First Application Container
resource containerApp1 'Microsoft.App/containerApps@2024-03-01' = {
  name: '${containerAppName}-1'
  location: location
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
        minReplicas: 1
        maxReplicas: 10
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

// Deploy the Second Application Container
resource containerApp2 'Microsoft.App/containerApps@2024-03-01' = {
  name: '${containerAppName}-2'
  location: location
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
        minReplicas: 1
        maxReplicas: 10
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
      probeProtocol: 'Https'
      probeIntervalInSeconds: 10
    }
  }
}

// Front Door Origin 1
resource frontDoorOrigin1 'Microsoft.Cdn/profiles/originGroups/origins@2021-06-01' = {
  name: 'AppOrigin1'
  parent: frontDoorOriginGroup
  properties: {
    hostName: containerApp1.properties.configuration.ingress.fqdn
    httpPort: 80
    httpsPort: 443
    originHostHeader: containerApp1.properties.configuration.ingress.fqdn
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
  }
}

// Front Door Origin 2
resource frontDoorOrigin2 'Microsoft.Cdn/profiles/originGroups/origins@2021-06-01' = {
  name: 'AppOrigin2'
  parent: frontDoorOriginGroup
  properties: {
    hostName: containerApp2.properties.configuration.ingress.fqdn
    httpPort: 80
    httpsPort: 443
    originHostHeader: containerApp2.properties.configuration.ingress.fqdn
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
  }
}

// Front Door Route
resource frontDoorRoute 'Microsoft.Cdn/profiles/afdEndpoints/routes@2021-06-01' = {
  name: 'MyRoute'
  parent: frontDoorEndpoint
  dependsOn: [
    frontDoorOrigin1
    frontDoorOrigin2
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
output applicationUrl string = 'https://${frontDoorEndpoint.properties.hostName}'
output app1Name string = containerApp1.name
output app2Name string = containerApp2.name
output app1Url string = 'https://${containerApp1.properties.configuration.ingress.fqdn}'
output app2Url string = 'https://${containerApp2.properties.configuration.ingress.fqdn}'
