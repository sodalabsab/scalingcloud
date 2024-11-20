@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name of the Container App Environment')
param environmentName string = 'appEnvironment'

@description('Application Container Image')
param applicationImage string = 'danielfroding/scalingcloud'

@description('Port for Application')
param applicationPort int = 80

@description('Minimum number of replicas')
param minReplicas int = 3 // Increased to start with 3 containers

@description('Maximum number of replicas')
param maxReplicas int = 20 // Allow scaling up to 20 containers

@description('Target average number of requests per second per replica')
param targetRequests int = 10


// Create a Container App Environment
resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: environmentName
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
