// --- Parameters passed from main.bicep ---
@description('The location for the resources (defaults to RG location)')
param location string = resourceGroup().location

@description('The full image name (server + repository + tag)')
param applicationImage string

@description('The ACR Login Server (e.g. sodalabs001.azurecr.io)')
param acrServer string

@description('The Resource ID of the User Assigned Identity used to pull images')
param userAssignedIdentityId string

@description('The Name of the Container App')
param containerAppName string = 'my-website'

var environmentName = 'appEnvironment'

// --- Existing App Environment ---
// We reference the environment created in main.bicep
resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: environmentName
  scope: resourceGroup()
}

// --- The Container App ---
resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppName
  location: location
  // Attach the "Badge" (Identity) to the App
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppEnvironment.id
    configuration: {
      // Tell the App to use the specific Identity for this Registry
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
        minReplicas: 1  // Good for labs to save resources
        maxReplicas: 10
        rules: [
          {
            name: 'http-requests-scaling'
            custom: {
              type: 'http'
              metadata: {
                concurrentRequests: '20'
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
