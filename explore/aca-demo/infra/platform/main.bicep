targetScope = 'subscription'

param location string = 'swedencentral'
param resourceGroupName string = 'rg-aca-platform'
param acrName string = 'acracaplatform${uniqueString(subscription().id)}'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module platform 'resources.bicep' = {
  name: 'platform-resources'
  scope: rg
  params: {
    location: location
    acrName: acrName
  }
}

output acrLoginServer string = platform.outputs.acrLoginServer
output acrName string = platform.outputs.acrName
output environmentId string = platform.outputs.environmentId
