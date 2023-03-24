@description('Application unique name')
param applicationName string

@description('Region to deploy resource.')
param region string

@description('DNSZone Object used to locate exsting DNS Zone Object.')
param dnsObject object

@description('DemoApp DNS Name https://xxxx.yourFQDN.com')
param demoAppName string

@description('Cosmos db instance id')
param cosmosdbId string

@description('Cosmos db api version')
param cosmosdbApiVersion string

@description('Cosmos db endpoint')
param cosmosdbEndpoint string

@description('Log analytics workspace Id')
param logAnalyticsWorkspaceId string

@description('TrafficManager Globally Unique Name')
param trafficManagerName string

param resourceTags object

// Variables 
var cosmosdbKey = listKeys(cosmosdbId, cosmosdbApiVersion).primaryMasterKey
var domainFQDN = '${demoAppName}.${dnsObject.name}'


// Configure Application Insights for WebApp - Required for Some Dashboard Outputs!
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

// Configure Availability Test that will be used for Kabana Dashboard
resource appWebTest 'Microsoft.Insights/webtests@2022-06-15' = {
  name: '${applicationName}-webtest'
  location: region
  kind: 'standard'
  tags: union(resourceTags,{
    'hidden-link:${appInsights.id}' : 'Resource'
  })
  properties: {
    Name: '${applicationName}-pingTest'
    Configuration: {
      WebTest: loadTextContent('../../code/webTest/webTest.xml') 
    }
    Locations: [
      {
        Id:  'us-ca-sjc-azr'
      }
      {
        Id:  'us-va-ash-azr'
      }
      {
        Id:  'emea-gb-db3-azr' 
      }
      {
        Id:  'apac-sg-sin-azr'
      }
    ]
    Kind: 'standard'
    Enabled: true
    Description: 'Run a Ping Test against FQDN.'
    Frequency: 300
    RetryEnabled: true
    Timeout: 120
    SyntheticMonitorId: '${applicationName}-webtest'
    Request: {
      FollowRedirects: true
      HttpVerb: 'Get'
      RequestUrl: domainFQDN
      ParseDependentRequests: false
    }
    ValidationRules: {
      ExpectedHttpStatusCode: 200
      IgnoreHttpStatusCode: true
      SSLCheck: false
    }
  }
}

// Deploy App Service Plan to be used by WebApp
resource appServerPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: '${applicationName}-asp'
  location: region
  tags: resourceTags
  sku: {
    name: 'S1'
    tier: 'Standard'
    size: 'S1'
    family: 'S'
    capacity: 2
  }
  kind: 'app'
  properties: {}
}

// Create Autoscale Config for AppServices
resource aspAutoscale 'Microsoft.Insights/autoscalesettings@2022-10-01' = {
  name: '${applicationName}-autoscale'
  location: region

  properties: {
    profiles: [
      {
        name: 'Auto created default scale condition'
        capacity: {
          default: '2'
          maximum: '5'
          minimum: '1'
        }
        rules: [
          {
            scaleAction: {
              cooldown: 'PT5M'
              direction: 'Increase'
              type: 'ChangeCount'
              value: '2'
            }
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: appServerPlan.id
              operator: 'GreaterThanOrEqual'
              statistic: 'Average'
              threshold: 60
              timeAggregation: 'Average'
              timeGrain: 'PT1M'
              timeWindow: 'PT5M'
              dividePerInstance: false
            }
          }
          {
            scaleAction: {
              cooldown: 'PT5M'
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
            }
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: appServerPlan.id
              operator: 'LessThanOrEqual'
              statistic: 'Average'
              threshold: 40
              timeAggregation: 'Average'
              timeGrain: 'PT1M'
              timeWindow: 'PT5M'
              dividePerInstance: false
            }
          }
        ]
      }
    ]
    notifications: []
    enabled: true
    targetResourceLocation: region
    targetResourceUri: appServerPlan.id
  }
}

// Deploy WebApp to host our Demo App
resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: '${applicationName}-web'
  location: region
  kind: 'app'
  tags: resourceTags
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: '${applicationName}-${toLower(replace(region, ' ', ''))}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${applicationName}-${toLower(replace(region, ' ', ''))}.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: appServerPlan.id
    reserved: false
    isXenon: false
    hyperV: false
    vnetRouteAllEnabled: false
    vnetImagePullEnabled: false
    vnetContentShareEnabled: false
    siteConfig: {
      numberOfWorkers: 1
      acrUseManagedIdentityCreds: false
      alwaysOn: false
      http20Enabled: false
      functionAppScaleLimit: 0
      minimumElasticInstanceCount: 0
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
          name: 'CosmosDb__Account'
          value: cosmosdbEndpoint
        }
        {
          name: 'CosmosDb__Key'
          value: cosmosdbKey
        }
      ]
    }
    scmSiteAlsoStopped: false
    clientAffinityEnabled: true
    clientCertEnabled: false
    clientCertMode: 'Required'
    hostNamesDisabled: false
    containerSize: 0
    dailyMemoryTimeQuota: 0
    httpsOnly: true
    redundancyMode: 'None'
    storageAccountRequired: false
    keyVaultReferenceIdentity: 'SystemAssigned'
  }
}

// Configure Diagnostic Settings For App Server Plan and WebApp
resource webAppDiagSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'LogAnalytics'
  scope: webApp
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
      }
      {
        category: 'AppServiceAuditLogs'
        enabled: true
      }
      {
        category: 'AppServicePlatformLogs'
        enabled: true
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

resource appServerDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'LogAnalytics'
  scope: appInsights
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

/*
  Setting up Custom Managed Certificates is a bit tricky in ARM/Bicep due to a bit of a Chicken and Egg issue. 
  You need to have a binding for the Custom Domain Name, configure Certificate, and then enable SNI with the Thumbprint of the Managed Cert. 
    1. First you need to create the CNAME record (in this case the one we plan to use for TrafficManager)
    2. Second you need to create HostName Binding with sslState Disabled (since the Cert doesn't exist)
    3. Next you'll want to create the Managed Certificate - this will require CNAME from Step 1
    4. Finally using Module (enableSNIWebApp) - enable SNI and Custom Domain on AppService with Thumbprint from Managed Cert
*/


// Begin Domain Verification Process - calling existing DNSZone and configure via VerificationType
module verifyDomain 'verifyDomain.bicep' = {
  name: '${applicationName}-verifyDomain'
  scope: resourceGroup(dnsObject.subscriptionId,dnsObject.resGroup)
  params: {
    dnsObject:dnsObject
    demoAppName: demoAppName
    verificationId: webApp.properties.customDomainVerificationId
    trafficManagerName: trafficManagerName
  }
}

// Add Custom Domain via HostName Binding with sslState 'Disabled'
resource hostNameBinding 'Microsoft.Web/sites/hostNameBindings@2022-03-01' = {
  name: domainFQDN
  parent: webApp
  dependsOn: [
    verifyDomain
  ]
  properties: {
    hostNameType: 'Verified'
    sslState: 'Disabled'
    siteName: webApp.name
  }
}

// Generate new Managed Certificate for App -- Depends on CNAME already existing from verifyDomain Module
resource generateManagedCert 'Microsoft.Web/certificates@2022-03-01' = {
  name: '${applicationName}-managedCert'
  location: region
  tags: resourceTags
  dependsOn: [
    hostNameBinding
  ]
  properties: {
    serverFarmId: appServerPlan.id
    canonicalName: domainFQDN
  }

}

// Enable SNI and Add Managed Cert
module enableSNIWebApp 'enableSNIWebApp.bicep' = {
  name: '${applicationName}-enableSNI'
  params: {
    demoAppFQDN: domainFQDN
    appServerHostCertThumbprint: generateManagedCert.properties.thumbprint
    appSiteName: webApp.name
  }
}

// Output AppServices Configs
output webAppFQDN string = webApp.properties.defaultHostName
output appInsightsName string = appInsights.name
output managedCertThumbprint string = generateManagedCert.properties.thumbprint
output managedCertName string = generateManagedCert.name
output webAppName string = webApp.name
output webAppResGroup string = webApp.properties.resourceGroup
output webAppRegion string = webApp.location
