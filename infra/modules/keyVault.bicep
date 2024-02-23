@description('Application unique name')
param applicationName string

@description('Region to deploy resource.')
param region string

@description('Log analytics workspace Id')
param logAnalyticsWorkspaceId string

param resourceTags object

resource keyvault 'Microsoft.KeyVault/vaults@2022-11-01' = {
  name: applicationName
  location: region
  tags: resourceTags
  properties:{
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
  createMode: 'default'
  enabledForDiskEncryption: true
  enabledForTemplateDeployment: true
  enabledForDeployment: true
  enableRbacAuthorization: true
  enableSoftDelete: true
  enablePurgeProtection: true
  }
}

resource keyvaultDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'LogAnalytics'
  scope: keyvault
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'audit'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
      }
      {
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output keyvaultName string = keyvault.name
output keyvaultId string = keyvault.id
