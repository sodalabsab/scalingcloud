@description('Location for all resources.')
param location string = resourceGroup().location

@description('Application Container Image')
param applicationImage string = 'danielfroding/scalingcloud'

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
          name: 'my-website-container'
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

output applicationUrl string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
