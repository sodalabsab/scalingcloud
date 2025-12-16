param location string = resourceGroup().location
param containerAppName string = 'aca-hello-world'
param environmentId string
param containerImage string
param registryServer string
param registryUsername string
@secure()
param registryPassword string
param minReplicas int = 1
param maxReplicas int = 1

resource containerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: environmentId
    configuration: {
      activeRevisionsMode: 'Single'
      secrets: [
        {
          name: 'registry-password'
          value: registryPassword
        }
      ]
      registries: [
        {
          server: registryServer
          username: registryUsername
          passwordSecretRef: 'registry-password'
        }
      ]
      ingress: {
        external: true
        targetPort: 80
      }
    }
    template: {
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
        rules: [
            {
                name: 'http-rule'
                http: {
                    metadata: {
                        concurrentRequests: '10'
                    }
                }
            }
        ]
      }
      containers: [
        {
          name: 'app'
          image: containerImage
          resources: {
            cpu: json('0.5')
            memory: '1.0Gi'
          }
        }
      ]
    }
  }
}

output fqdn string = containerApp.properties.configuration.ingress.fqdn
