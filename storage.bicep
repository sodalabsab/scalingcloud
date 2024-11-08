// Parameters
@description('The location where the storage account should be created.')
param location string = 'swedencentral'

@description('The name of the storage account to create. Must be globally unique.')
param storageAccountName string = 'sodalabscourse'

@description('The name of the file share to create in the storage account.')
param fileShareName string = 'nginx-content'

@description('The name of the blob container to create in the storage account.')
param blobContainerName string = 'website-content'


// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false // Disallows public access to blob containers
    accessTier: 'Hot'
  }
}

// File Service (Intermediate Resource)
resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2023-05-01' = {
  name: 'default'
  parent: storageAccount
}

// File Share in Storage Account
resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-05-01' = {
  name: fileShareName
  parent: fileService
  properties: {
    enabledProtocols: 'SMB'
    shareQuota: 5 // Set quota in GB for the file share
  }
}

// Blob Service (Intermediate Resource)
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  name: 'default'
  parent: storageAccount
}

// Blob Container in Storage Account
resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  name: blobContainerName
  parent: blobService
  properties: {
    publicAccess: 'None' // Ensures no public access for added security
  }
}

// Output URLs
output storageAccountName string = storageAccount.name
output fileShareUrl string = 'https://${storageAccount.name}.file.core.windows.net/${fileShareName}'
output blobContainerUrl string = 'https://${storageAccount.name}.blob.core.windows.net/${blobContainerName}'


/*
az storage blob upload \
  --account-name sodalabscourse \             
  --container-name website-content \      
  --name massively.zip \
  --file html5up-massively.zip \
  --auth-mode key
  */