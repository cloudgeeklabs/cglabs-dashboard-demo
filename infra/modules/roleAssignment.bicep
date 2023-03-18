@description('Grafana SMI Principalid')
param grafanaPrincipalId string

var roleAssignmentObject = {
  role1: {
    name: guid('readerRole',resourceGroup().id) // has to be globally unique - thus using resourceGroup().id as part of GUID
    roleDefinitionId: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
    principalId: grafanaPrincipalId
    principalType: 'ServicePrincipal'
  }
  role2: {
    name: guid('monitorReaderRole',resourceGroup().id) // has to be globally unique - thus using resourceGroup().id as part of GUID
    roleDefinitionId: '43d0d8ad-25c7-4714-9337-8ba259a9fe05'
    principalId: grafanaPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Configure RBAC on ResourceGroup to allow Frafana to Access all Data
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for role in items(roleAssignmentObject): {
  name: role.value.name
  scope: resourceGroup()
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', role.value.roleDefinitionId)
    principalId: role.value.principalId
    principalType: role.value.principalType
  }
}]
