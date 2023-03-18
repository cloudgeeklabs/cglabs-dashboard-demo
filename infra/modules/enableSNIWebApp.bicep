@description('App site name')
param appSiteName string

@description('FQDN to pass into CNAM Record for TrafficManager.')
param demoAppFQDN string

@description('App server certificate thumbprint')
param appServerHostCertThumbprint string

// Enable SNI on AppServices
resource appSiteDomainEnable 'Microsoft.Web/sites/hostNameBindings@2022-03-01' = {
  name: '${appSiteName}/${demoAppFQDN}'
  properties: {
    sslState: 'SniEnabled'
    thumbprint: appServerHostCertThumbprint
  }
}
