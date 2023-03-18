@description('Application unique name')
param applicationName string

@description('CNAME Record - Must be Globally Unique')
param cnameRecordValue string

@description('Log analytics workspace Id')
param logAnalyticsWorkspaceId string

@description('Primary region FQDN')
param primaryRegionFqdn string

@description('Secondary region FQDN')
param secondaryRegionFqdn string

param resourceTags object

// Configure TM Profile and Confgirue webApp FQDN Endpoints
resource trafficManager 'Microsoft.Network/trafficmanagerprofiles@2022-04-01-preview' = {
  name: applicationName
  location: 'global'
  tags: resourceTags
  properties: {
    profileStatus: 'Enabled'
    trafficRoutingMethod: 'Weighted'
    dnsConfig: {
      relativeName: cnameRecordValue
      ttl: 60
    }
    monitorConfig: {
      profileMonitorStatus: 'Online'
      protocol: 'HTTPS'
      port: 443
      path: '/l'
      intervalInSeconds: 30
      toleratedNumberOfFailures: 3
      timeoutInSeconds: 10
      customHeaders: []
      expectedStatusCodeRanges: []
    }
    endpoints: [
      {
        name: 'primary'
        type: 'Microsoft.Network/TrafficManagerProfiles/ExternalEndpoints'
        properties: {
          endpointStatus: 'Enabled'
          target: primaryRegionFqdn
          weight: 50
        }
      }
      {
        name: 'secondary'
        type: 'Microsoft.Network/TrafficManagerProfiles/ExternalEndpoints'
        properties: {
          endpointStatus: 'Enabled'
          target: secondaryRegionFqdn
          weight: 50
        }
      }
    ]
    trafficViewEnrollmentStatus: 'Disabled'
  }
}

// Config Diagnostic Settings
resource trafficManagerDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'LogAnalytics'
  scope: trafficManager
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
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


@description('Name of the traffic manager')
output trafficManagerName string = trafficManager.name
output trafficManagerFQDN string = trafficManager.properties.dnsConfig.fqdn
