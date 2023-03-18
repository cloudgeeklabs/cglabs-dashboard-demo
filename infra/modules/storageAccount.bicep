@description('Application unique name')
param applicationName string

@description('Region to deploy resource.')
param region string

param resourceTags object

resource logStorage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: applicationName
  location: region
  tags: resourceTags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  name: 'default'
  parent: logStorage
}

resource logContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  name: 'billing-logs'
  parent: blobService
  properties: {
    publicAccess: 'Blob'
  }
}

// Output logStorage Information
output logStorageAccountId string = logStorage.id
output logStorageAccountName string = logStorage.name
output logStorageAccountBlobEndpoint string = logStorage.properties.primaryEndpoints.blob
