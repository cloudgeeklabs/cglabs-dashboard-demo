@description('Verificaton Id')
param verificationId string

@description('DemoApp DNS Name https://xxxx.yourFQDN.com')
param demoAppName string

@description('DNSZone Object used to locate exsting DNS Zone Object.')
param dnsObject object

@description('TrafficManager Globally Unique Name')
param trafficManagerName string

// This is gonna to complain about not usin hardcoded URLs. In this case we have no choice since we are not creating the TM until after this step. 
var trafficManagerCname = '${trafficManagerName}.trafficmanager.net'

// Reference Existing DNS
resource dns 'Microsoft.Network/dnsZones@2018-05-01' existing = {
  name: dnsObject.name
}

// Create TXT Record for Domain Validation
resource domainVerifyTXT 'Microsoft.Network/dnsZones/TXT@2018-05-01' = {
  name: 'asuid.${demoAppName}'
  parent: dns
  properties: {
    TTL: 3600
    TXTRecords: [
      {
        value: [
          verificationId
        ]
      }
    ]
  }
}

// Create CNAME for Traffic Manager
resource domainVerifyCNAME 'Microsoft.Network/dnsZones/CNAME@2018-05-01' = {
  name: demoAppName
  parent: dns
  properties: {
    TTL: 3600
    CNAMERecord: {
       cname: trafficManagerCname
    }
  }
}

// Output DnsId
output domainId string = dns.id



