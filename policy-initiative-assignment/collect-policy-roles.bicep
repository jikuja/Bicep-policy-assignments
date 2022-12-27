targetScope = 'subscription'

param policyDefinitionIds array
@description('Extra naming to use for multiple deployments into single scope')
param deploymentNamePostfix string = ''

/////////////////////////////////////

module Inner 'collect-policy-roles-inner.bicep' = [for (item, index) in policyDefinitionIds: {
  name: 'Inner-${index}-${deploymentNamePostfix}'
  params: {
    policyDefinitionId: item
  }
}]

output policyIds array = [for (item, index) in policyDefinitionIds: [
  Inner[index].outputs.policyIds
]]
