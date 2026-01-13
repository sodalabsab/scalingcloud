@description('Primary location for the resources.')
param primaryLocation string = resourceGroup().location

@description('Secondary location for the resources.')
param secondaryLocation string = 'westeurope'

@description('Container image for the web app from Docker Hub.')
param containerImage string = '<acr-name>.azurecr.io/scalingcloud:latest'

@description('Name of the Traffic Manager profile.')
param trafficManagerName string = 'myUniqueTrafficManagerProfile323'

// Environment for Container Apps
resource primaryContainerEnvironment 'Microsoft.App/managedEnvironments@2022-10-01' = {
  name: 'primaryContainerEnvironment'
  location: primaryLocation
  properties: {}
}

resource secondaryContainerEnvironment 'Microsoft.App/managedEnvironments@2022-10-01' = {
  name: 'secondaryContainerEnvironment'
  location: secondaryLocation
  properties: {}
}

// Container Apps
resource primaryContainerApp 'Microsoft.App/containerApps@2022-10-01' = {
  name: 'my-containerapp-primary'
  location: primaryLocation
  properties: {
    managedEnvironmentId: primaryContainerEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 80
        traffic: [
          {
            weight: 100
            latestRevision: true
            label: 'primary'
          }
        ]
      }
    }
    template: {
      containers: [
        {
          name: 'webapp'
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

resource secondaryContainerApp 'Microsoft.App/containerApps@2022-10-01' = {
  name: 'my-containerapp-secondary'
  location: secondaryLocation
  properties: {
    managedEnvironmentId: secondaryContainerEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 80
        traffic: [
          {
            weight: 100
            latestRevision: true
            label: 'secondary'
          }
        ]
      }
    }
    template: {
      containers: [
        {
          name: 'webapp'
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

// Traffic Manager Profile
resource trafficManager 'Microsoft.Network/trafficManagerProfiles@2022-04-01' = {
  name: trafficManagerName
  location: 'global'
  properties: {
    profileStatus: 'Enabled'
    trafficRoutingMethod: 'Performance'
    dnsConfig: {
      relativeName: trafficManagerName
      ttl: 30
    }
    monitorConfig: {
      protocol: 'HTTPS'
      port: 8080
      path: '/'
    }
    endpoints: [
      {
        name: 'primaryEndpoint'
        type: 'Microsoft.Network/trafficManagerProfiles/ExternalEndpoints'
        properties: {
          target: primaryContainerApp.properties.configuration.ingress.fqdn
          endpointStatus: 'Enabled'
          alwaysServe: 'Disabled'
          endpointLocation: primaryLocation
        }
      }
      {
        name: 'secondaryEndpoint'
        type: 'Microsoft.Network/trafficManagerProfiles/ExternalEndpoints'
        properties: {
          target: secondaryContainerApp.properties.configuration.ingress.fqdn
          endpointStatus: 'Enabled'
          alwaysServe: 'Disabled'
          endpointLocation: secondaryLocation
        }
      }
    ]
  }
}
