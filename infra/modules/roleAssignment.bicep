targetScope='subscription'

@description('Grafana SMI Principalid')
param grafanaPrincipalId string

@description('AAD User to be configured for Grafana Dashboard Admin.')
param grafanaAADId string

@description('FunctionApp SME Principlal Id - Add as READER to Subscription')
param functionAppSME string

var roleAssignmentObject = {
  role1: {
    name: guid('readerRole',subscription().id) // has to be globally unique - thus using subscription().id as part of GUID
    roleDefinitionId: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
    principalId: grafanaPrincipalId
    principalType: 'ServicePrincipal'
    enabled: true
  }
  role2: {
    name: guid('monitorReaderRole',subscription().id) // has to be globally unique - thus using subscription().id as part of GUID
    roleDefinitionId: '43d0d8ad-25c7-4714-9337-8ba259a9fe05'
    principalId: grafanaPrincipalId
    principalType: 'ServicePrincipal'
    enabled: true
  }
  role3: {
    name: guid('grafanaAdmin',subscription().id) // has to be globally unique - thus using subscription().id as part of GUID
    roleDefinitionId: '22926164-76b3-42b3-bc55-97df8dab3e41'
    principalId: grafanaAADId
    principalType: 'user'
    enabled: true
  }
  role4: {
    name: guid('keyVaultAdministrator',subscription().id) // has to be globally unique - thus using subscription().id as part of GUID
    roleDefinitionId: '00482a5a-887f-4fb3-b363-3b7fe8e74483'
    principalId: grafanaAADId
    principalType: 'user'
    enabled: true
  }
  role5: {
    name: guid('readerRoleFunctionApp',subscription().id) // has to be globally unique - thus using subscription().id as part of GUID
    roleDefinitionId: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
    principalId: functionAppSME
    principalType: 'ServicePrincipal'
    enabled: true
  }
}

// Configure RBAC on ResourceGroup to allow Grafana to Access all Data
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for role in items(roleAssignmentObject): {
  name: role.value.name
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', role.value.roleDefinitionId)
    principalId: role.value.principalId
    principalType: role.value.principalType
  }
}]
