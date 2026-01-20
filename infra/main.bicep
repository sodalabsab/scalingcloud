@description('The Azure region where all resources will be created.')
param location string = resourceGroup().location

// --- GitHub Settings (Required) ---
@description('GitHub Organization or User name (e.g. sodalabsab)')
param githubUser string 

@description('GitHub Repository name (e.g. scaling-cloud)')
param githubRepo string 

// --- Naming Parameters (With Defaults) ---
@description('Name of the Container Registry. Must be globally unique.')
param acrName string = 'sodalabs001'

// --- Internal Variables (Standardized) ---
var identityNamePull = 'id-app-pull'
var identityNamePush = 'id-github-push'
var environmentName  = 'appEnvironment'
var acrSku           = 'Basic'

// --- 1. Create Core Infrastructure ---
resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: acrName
  location: location
  sku: { name: acrSku }
  properties: { adminUserEnabled: false }
}

resource idPull 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityNamePull
  location: location
}

resource idPush 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityNamePush
  location: location
}

// --- 2. Assign Permissions (RBAC) ---
// Using variables for Role IDs keeps the code clean (these GUIDs rarely change)
var acrPullRole = '7f951dda-4ed3-4680-a7ca-43fe172d538d'
var acrPushRole = '8311e382-0749-4cb8-b61a-304f252e45ec'

resource assignPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, idPull.id, acrPullRole)
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRole)
    principalId: idPull.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource assignPush 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, idPush.id, acrPushRole)
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPushRole)
    principalId: idPush.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource federation 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = {
  parent: idPush
  name: 'github-federation'
  properties: {
    issuer: 'https://token.actions.githubusercontent.com'
    subject: 'repo:${githubUser}/${githubRepo}:ref:refs/heads/main'
    audiences: ['api://AzureADTokenExchange']
  }
}

// --- 3. Create Environment ---
resource env 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: environmentName
  location: location
  properties: {
    workloadProfiles: [{ name: 'Consumption', workloadProfileType: 'Consumption' }]
  }
}

@description('Optional: Override the image to deploy. Useful for bootstrapping.')
param containerImage string = ''

// --- 4. Call the App Module ---
module appDeployment '../lab3/lab.bicep' = {
  name: 'deploy-container-app'
  dependsOn: [ 
    env 
  ]
  params: {
    location: location
    applicationImage: !empty(containerImage) ? containerImage : '${acr.properties.loginServer}/my-website:latest'
    userAssignedIdentityId: idPull.id
    acrServer: acr.properties.loginServer
    // If you parameterized the Environment ID in lab.bicep, pass it here too:
    // containerAppEnvironmentId: env.id
  }
}
