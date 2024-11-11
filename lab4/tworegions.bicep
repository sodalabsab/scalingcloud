@description('Primary location for the resources.')
param primaryLocation string = 'swedencentral'

@description('Secondary location for the resources.')
param secondaryLocation string = 'westeurope'

@description('Container image for the web app from Azure Container Registry (ACR).')
param containerImage string

@description('Name of the Traffic Manager profile.')
param trafficManagerName string = 'myTrafficManagerProfile'

resource primaryContainerAppEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: 'myPrimaryContainerAppEnv'
  location: primaryLocation
  properties: {
  }
}

resource secondaryContainerAppEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: 'mySecondaryContainerAppEnv'
  location: secondaryLocation
  properties: {
  }
}

resource primaryContainerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'my-website-primary'
  location: primaryLocation
  properties: {
    managedEnvironmentId: primaryContainerAppEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 80
      }
      activeRevisionsMode: 'Multiple'
      registries: [
        {
          server: 'scalingcontainers.azurecr.io'
          identity: 'SystemAssigned'  
        }
      ]
    }
    template: {
      containers: [
        {
          image: containerImage
          name: 'my-website-primary-container'
          resources: {
            cpu: json('0.5')
            memory: '1.0Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
        rules: [
          {
            name: 'http-scale-rule'
            http: {
              metadata: {
                concurrentRequests: '50'
              }
            }
          }
        ]
      }
    }
  }
}

resource secondaryContainerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'my-website-secondary'
  location: secondaryLocation
  properties: {
    managedEnvironmentId: secondaryContainerAppEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 80
      }
      activeRevisionsMode: 'Multiple'
      registries: [
        {
          server: 'scalingcontainers.azurecr.io'
          identity: 'SystemAssigned'  
        }
      ]
    }
    template: {
      containers: [
        {
          image: containerImage
          name: 'my-website-secondary-container'
          resources: {
            cpu: json('0.5')
            memory: '1.0Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
        rules: [
          {
            name: 'http-scale-rule'
            http: {
              metadata: {
                concurrentRequests: '50'
              }
            }
          }
        ]
      }
    }
  }
}

