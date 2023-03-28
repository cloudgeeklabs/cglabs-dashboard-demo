@description('Application unique name')
param applicationName string

@description('Region for FunctionApp')
param region string

@description('DemoApp URL to pass into AppSettings')
param demoAppUrl string

@description('Log analytics workspace Id')
param logAnalyticsWorkspaceId string

param resourceTags object


// Create StorageAccount for FunctionApp
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: '${replace(applicationName,'-','')}sa'
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

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${applicationName}-ai'
  location: region
  kind: 'web'
  tags: resourceTags
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    Request_Source: 'IbizaAIExtension'
    RetentionInDays: 90
    WorkspaceResourceId: logAnalyticsWorkspaceId
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}


// Deploy App Service Plan to be used by FunctionApp
resource appServerPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: '${applicationName}-asp'
  location: region
  tags: resourceTags
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
}

// Deploy FunctionApp Resource
resource functionApp 'Microsoft.Web/sites@2020-06-01' = {
  name: applicationName
  location: region
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned' 
  }
  properties: {
    httpsOnly: true
    serverFarmId: appServerPlan.id
    clientAffinityEnabled: true
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'Recommended'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'powershell'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'DEMOAPPURL'
          value: demoAppUrl
        }
      ]
    }
  }
}

// Configure Diagnostic Logs
resource funcAppDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'LogAnalytics'
  scope: functionApp
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: []
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

//Outputs
output functionAppId string = functionApp.id
output functionAppSME string = functionApp.identity.principalId
output functionAppName string = functionApp.name

