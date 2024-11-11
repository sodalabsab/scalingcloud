@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name of the Container App Environment')
param environmentName string = 'appEnvironment'

@description('Application Container Image')
param applicationImage string = 'scalecontainers.azurecr.io/my-website:latest'

@description('Port for Application')
param applicationPort int = 80

@description('Minimum number of replicas')
param minReplicas int = 3 // Increased to start with 3 containers

@description('Maximum number of replicas')
param maxReplicas int = 20 // Allow scaling up to 20 containers

@description('Target average number of requests per second per replica')
param targetRequests int = 50


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

output applicationUrl string = 'https://${applicationContainerApp.properties.configuration.ingress.fqdn}'
