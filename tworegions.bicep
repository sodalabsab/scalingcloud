@description('Primary location for the resources.')
param primaryLocation string = 'swedencentral'

@description('Secondary location for the resources.')
param secondaryLocation string = 'westeurope'

@description('Name of the App Service Plan.')
param appServicePlanName string = 'scalePlan'

@description('Name of the primary web app.')
param primaryWebAppName string = 'myPrimaryScaleTestApp'

@description('Name of the secondary web app.')
param secondaryWebAppName string = 'mySecondaryScaleTestApp'

@description('Name of the Traffic Manager.')
param trafficManagerName string = 'myTrafficManager'

resource primaryAppServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: primaryLocation
  sku: {
    tier: 'Standard'
    name: 'S1'
    capacity: 1
  }
  properties: {
    reserved: true
  }
}

resource secondaryAppServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: '${appServicePlanName}-secondary'
  location: secondaryLocation
  sku: {
    tier: 'Standard'
    name: 'S1'
    capacity: 1
  }
  properties: {
    reserved: true
  }
}

resource primaryWebApp 'Microsoft.Web/sites@2023-12-01' = {
  name: primaryWebAppName
  location: primaryLocation
  properties: {
    serverFarmId: primaryAppServicePlan.id
    siteConfig: {
      linuxFxVersion: 'NODE|20-lts'  // Primary web app runtime
    }
  }
}

resource secondaryWebApp 'Microsoft.Web/sites@2023-12-01' = {
  name: secondaryWebAppName
  location: secondaryLocation
  properties: {
    serverFarmId: secondaryAppServicePlan.id
    siteConfig: {
      linuxFxVersion: 'NODE|20-lts'  // Secondary web app runtime
    }
  }
}

resource trafficManager 'Microsoft.Network/trafficManagerProfiles@2022-04-01' = {
  name: trafficManagerName
  location: 'global'
  properties: {
    profileStatus: 'Enabled'
    trafficRoutingMethod: 'Performance'  // Routing based on the best performing region
    dnsConfig: {
      relativeName: trafficManagerName
      ttl: 30
    }
    monitorConfig: {
      protocol: 'HTTP'
      port: 80
      path: '/'
    }
    endpoints: [
      {
        name: 'primaryEndpoint'
        type: 'Microsoft.Network/trafficManagerProfiles/azureEndpoints'
        properties: {
          targetResourceId: primaryWebApp.id
          endpointStatus: 'Enabled'
        }
      }
      {
        name: 'secondaryEndpoint'
        type: 'Microsoft.Network/trafficManagerProfiles/azureEndpoints'
        properties: {
          targetResourceId: secondaryWebApp.id
          endpointStatus: 'Enabled'
        }
      }
    ]
  }
}

resource primaryAutoScaleSettings 'Microsoft.Insights/autoscalesettings@2022-10-01' = {
  name: '${primaryWebAppName}-autoscale'
  location: primaryLocation
  properties: {
    enabled: true
    targetResourceUri: primaryAppServicePlan.id
    profiles: [
      {
        name: 'autoscaleProfile'
        capacity: {
          minimum: '1'
          maximum: '3'
          default: '1'
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricNamespace: 'Microsoft.Web/serverfarms'
              metricResourceUri: primaryAppServicePlan.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 70
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricNamespace: 'Microsoft.Web/serverfarms'
              metricResourceUri: primaryAppServicePlan.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 30
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
        ]
      }
    ]
  }
}

resource secondaryAutoScaleSettings 'Microsoft.Insights/autoscalesettings@2022-10-01' = {
  name: '${secondaryWebAppName}-autoscale'
  location: secondaryLocation
  properties: {
    enabled: true
    targetResourceUri: secondaryAppServicePlan.id
    profiles: [
      {
        name: 'autoscaleProfile'
        capacity: {
          minimum: '1'
          maximum: '3'
          default: '1'
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricNamespace: 'Microsoft.Web/serverfarms'
              metricResourceUri: secondaryAppServicePlan.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 70
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricNamespace: 'Microsoft.Web/serverfarms'
              metricResourceUri: secondaryAppServicePlan.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 30
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
        ]
      }
    ]
  }
}
