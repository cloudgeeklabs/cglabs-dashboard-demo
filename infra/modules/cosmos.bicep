@description('Application unique name')
param applicationName string

@description('Primary region of the application')
param primaryRegion string

@description('Failover region for cosmos db')
param secondaryRegion string

@description('Log analytics workspace Id')
param logAnalyticsWorkspaceId string

param resourceTags object

// Deploy CosmoDB
resource cosmosdb 'Microsoft.DocumentDB/databaseAccounts@2022-08-15' = {
  name: applicationName
  location: primaryRegion
  kind: 'GlobalDocumentDB'
  tags: resourceTags
  identity: {
    type: 'None'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
    enableAutomaticFailover: false
    enableMultipleWriteLocations: true
    isVirtualNetworkFilterEnabled: false
    virtualNetworkRules: []
    disableKeyBasedMetadataWriteAccess: false
    enableFreeTier: false
    enableAnalyticalStorage: false
    analyticalStorageConfiguration: {
      schemaType: 'WellDefined'
    }
    databaseAccountOfferType: 'Standard'
    defaultIdentity: 'FirstPartyIdentity'
    networkAclBypass: 'None'
    disableLocalAuth: false
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
      maxIntervalInSeconds: 5
      maxStalenessPrefix: 100
    }
    locations: [
      {
        locationName: primaryRegion
        failoverPriority: 0
        isZoneRedundant: false
      }
      {
        locationName: secondaryRegion
        failoverPriority: 1
        isZoneRedundant: false
      }
    ]
    cors: []
    capabilities: []
    ipRules: []
    backupPolicy: {
      type: 'Periodic'
      periodicModeProperties: {
        backupIntervalInMinutes: 240
        backupRetentionIntervalInHours: 24
        backupStorageRedundancy: 'Geo'
      }
    }
    networkAclBypassResourceIds: []
  }
}

// Configure Diagnostic Settings for CosmoDB
resource cosmosdbDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'LogAnalytics'
  scope: cosmosdb
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'DataPlaneRequests'
        enabled: true
      }
      {
        category: 'QueryRuntimeStatistics'
        enabled: true
      }
      {
        category: 'PartitionKeyStatistics'
        enabled: true
      }
      {
        category: 'PartitionKeyRUConsumption'
        enabled: true
      }
      {
        category: 'ControlPlaneRequests'
        enabled: true
      }
      {
        category: 'TableApiRequests'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Requests'
        enabled: true
      }
    ]
  }
}

// Output CosmoDB Settings
output cosmosdbName string = cosmosdb.name
output cosmosdbId string = cosmosdb.id
output cosmosdbApiVersion string = cosmosdb.apiVersion
output cosmosdbEndpoint string = cosmosdb.properties.documentEndpoint
