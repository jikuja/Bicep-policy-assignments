targetScope = 'subscription'

param policyDefinitionId string

resource ExistingPolicyDefinition 'Microsoft.Authorization/policyDefinitions@2021-06-01' existing = {
  scope: tenant()
  name: last(split(policyDefinitionId, '/'))
}

var then = string(ExistingPolicyDefinition.properties.policyRule.then)
var policyHasRoleDefinitionIds = contains(then, 'roleDefinitionIds')
var roleDefinitionIds = policyHasRoleDefinitionIds ? ExistingPolicyDefinition.properties.policyRule.then.details.roleDefinitionIds : []

output policyHasRoleDefinitionIds bool = policyHasRoleDefinitionIds
output policyIds array = policyHasRoleDefinitionIds ? roleDefinitionIds : []
