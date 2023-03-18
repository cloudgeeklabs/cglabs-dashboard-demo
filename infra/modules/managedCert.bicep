@description('Application unique name')
param applicationName string

@description('Region to Deploy the Cert.')
param region string

@description('App Server Plan')
param appServerPlanId string

@description('DNSZone Object used to locate exsting DNS Zone Object.')
param dnsObject object

@description('DemoApp DNS Name https://xxxx.yourFQDN.com')
param demoAppName string

param resourceTags object// Generate new Managed Certificate for App


resource generateManagedCert 'Microsoft.Web/certificates@2022-03-01' = {
  name: applicationName
  location: region
  tags: resourceTags
  properties: {
    serverFarmId: appServerPlan.id
    canonicalName: domainFQDN
  }
}
