targetScope='subscription'

@description('Primary region of the application')
param primaryRegion string

@description('Secondary region of the application')
param secondaryRegion string

@description('Prefix for resources to use in common')
param resourcePrefix string

@description('DemoApp DNS Name https://xxxx.yourFQDN.com')
param demoAppName string

@description('Existing DNS Zone Object')
param dnsObject object

@description('Set current Time for Tagging our Deployments!')
param dateTime string = utcNow('u')

@description('Default resourceTags defined for all resources in the Demo!')
param resourceTags object


// Setup main.bicep Variables Section
var domainFQDN = '${demoAppName}.${dnsObject.name}'
var prefix = toLower(resourcePrefix)
var trafficManagerName = '${demoAppName}${uniqueString(primaryRegion)}' //Must be Globally Unique
var tags = union(resourceTags,{
  LastDeployment: dateTime // updating tags to include "LastDeployment" date/time value
})
var appResources = {
  app1: {
    name: '${prefix}-${primaryRegion}-demoapp'
    region: primaryRegion
    ResGroup: createResGroup[1].name
  }
  app2: {
    name: '${prefix}-${secondaryRegion}-demoapp'
    region: secondaryRegion
    ResGroup: createResGroup[2].name
  }
}
var resGroupObject = {
  rg1:{
    name: '${prefix}-${primaryRegion}-${demoAppName}-shared'
    location: primaryRegion
    tags: union(tags,{
      Notes: 'Resource Group contains Shared Resoures for Dashboard Demo'
    })
  }
  rg2:{
    name: '${prefix}-${primaryRegion}-${demoAppName}-primary'
    location: primaryRegion
    tags: union(tags,{
      Notes: 'Resource Group contains Shared Resoures for Primary DemoApp for Dashboard Demo'
    })
  }
  rg3:{
    name: '${prefix}-${secondaryRegion}-${demoAppName}-secondary'
    location: secondaryRegion
    tags: union(tags,{
      Notes: 'Resource Group contains Shared Resoures for Secondary DemoApp for Dashboard Demo'
    })
  }
}

// Deploy ResourceGroups used for the Demo | will create 3 different Resource Groups defined in var.resGroupObject
resource createResGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = [for rg in items(resGroupObject): {
  name: rg.value.name
  location: rg.value.location
  tags: rg.value.tags
}]

// Deploy Logs Storage Account - will use this to collect Billing and CustomLogs for Dashboard
module logsSA 'modules/storageAccount.bicep' = {
  name: '${prefix}-${demoAppName}-loggingStorageAccount'
  scope: resourceGroup(createResGroup[0].name)
  params: {
    resourceTags: union(tags, {
      Notes: 'Used to store Billing and AAD Logs for Dashboard Usage!'
    })
    applicationName: '${prefix}logstorage'
    region: primaryRegion
  }
}

// Deploy Log Analytics Workspace for DemoApp Diagnostic Logs - this will feed Dashboard!
module logAnalytics 'modules/logAalytics.bicep' = {
  name: '${prefix}-${demoAppName}-law'
  scope: resourceGroup(createResGroup[0].name)
  params: {
    resourceTags: tags
    primaryRegion: primaryRegion
    workspaceName: '${prefix}-${demoAppName}-law'
  }
}

// Deploy Azure Managed Grafana
module grafanaDashboard 'modules/grafana.bicep' = {
  name: '${prefix}-${demoAppName}-grafana'
  scope: resourceGroup(createResGroup[0].name)
  params: {
    applicationName: '${prefix}-grafana' //Workspace names must be between 2 to 23 characters long
    resourceTags: tags
    region: primaryRegion
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
  }
}

// Set Grafana SMI to required RBAC Roles on all ResourceGroups() defined in var.resGroupObject
module roleAssignment 'modules/roleAssignment.bicep' = [for rg in items(resGroupObject):  {
  name: '${rg.value.name}-roleAssignments'
  scope: resourceGroup(rg.value.name)
  params: {
    grafanaPrincipalId: grafanaDashboard.outputs.grafanaSMI
  }
}]

// Deploy cosmoDB for our Regionally Distributed App
module cosmosdb 'modules/cosmos.bicep' = {
  name: '${prefix}-${demoAppName}-cosmodb'
  scope: resourceGroup(createResGroup[0].name)
  params: {
    resourceTags: tags
    applicationName: '${prefix}-${demoAppName}-cosmodb'
    secondaryRegion: secondaryRegion
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
    primaryRegion: primaryRegion
  }
}

// Deploy WebApp and Associated Services
@batchSize(1)
module webApp 'modules/webApp.bicep' = [for app in items(appResources): {
  name: app.value.name
  scope: resourceGroup(app.value.resGroup)
  params: {
    resourceTags: union(tags,{
      'WebApp Name': app.value.name
      Region: app.value.region
    })
    applicationName: app.value.name
    demoAppName: demoAppName
    dnsObject: dnsObject
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
    region: app.value.region
    cosmosdbApiVersion: cosmosdb.outputs.cosmosdbApiVersion
    cosmosdbEndpoint: cosmosdb.outputs.cosmosdbEndpoint
    cosmosdbId: cosmosdb.outputs.cosmosdbId
    trafficManagerName: trafficManagerName
  }
}]

// Deploy Traffic Manager
module trafficManager 'modules/trafficManager.bicep' = {
  name: '${prefix}-${demoAppName}-tm'
  scope: resourceGroup(createResGroup[0].name)
  params: {
    resourceTags: tags
    applicationName: '${prefix}-${demoAppName}-tm'
    cnameRecordValue: trafficManagerName
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
    primaryRegionFqdn: webApp[0].outputs.webAppFQDN
    secondaryRegionFqdn: webApp[1].outputs.webAppFQDN
  }
}

// Output Primary Information
output dateTime string = dateTime
output subscriptionId string = subscription().subscriptionId
output demoAppSharedResGroupName string = createResGroup[0].name
output demoAppPrimaryResGroupName string = createResGroup[1].name
output demoAppSecondaryResGroupName string = createResGroup[2].name
output demoAppName string = demoAppName
output primaryRegion string = primaryRegion
output secondaryRegion string = secondaryRegion
output domainFQDN string = domainFQDN

// Output Storage Account Info
output logsStorageAccountName string = logsSA.outputs.logStorageAccountName
output logStorageAccountBlobEndpoint string = logsSA.outputs.logStorageAccountBlobEndpoint

// Output Log Analytic Workspace Info
output logAnalyticsWorkspaceId string = logAnalytics.outputs.logAnalyticsWorkspaceId
output logAnalyticsWorkspaceName string = logAnalytics.outputs.logAnalyticsWorkspaceName

// Output Grafana Dashboard Info
output grafanaSMI string = grafanaDashboard.outputs.grafanaSMI
output grafanaOutboundIP01 string = grafanaDashboard.outputs.grafanaOutboundIP01
output grafanaOutboundIP02 string = grafanaDashboard.outputs.grafanaOutboundIP02
output grafanaEndpoint string = grafanaDashboard.outputs.grafanaEndpoint
