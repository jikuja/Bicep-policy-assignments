targetScope = 'subscription'

param requiredRoles array
param policyId string
param policyName string
param principalId string
param version string

resource RoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for (roleId, index) in requiredRoles: {
  name: guid(subscription().subscriptionId, policyId, roleId)
  properties: {
    principalId: principalId
    roleDefinitionId: roleId
    principalType: 'ServicePrincipal'
    description: '${policyName}: remediation. Version: ${version}'
  }
}]

output roleAssignmentIds array = [for (item, index) in requiredRoles:  RoleAssignment[index].id]
