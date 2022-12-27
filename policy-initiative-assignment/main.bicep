targetScope = 'subscription'

@description('Location to deploy resources')
param location string
@description('Policy definition id in short form')
param policyId string
@description('enforcementMode for policy assignment')
@allowed(['Default', 'DoNotEnforce'])
param enforcementMode string = 'Default'
@description('Disable role assignments')
param disableRoleAssignment bool = false
@description('Extra naming to use for multiple deployments into single scope')
param extraName string = ''
@description('Extra description to use for multiple deployments into single scope')
param extraDescription string = ''
@description('Deployment name postfix')
param deploymentNamePostfix string = ''

// policy initiative properties
param nonComplianceMessages array = []
param notScopes array = []
param overrides array = []
@description('Policy definition parameters')
param parameters object = {}
param resourceSelectors array = []

var version = '2022-12-18'

resource ExistingPolicyInitiativeDefinition 'Microsoft.Authorization/policySetDefinitions@2021-06-01' existing = {
  scope: tenant()
  name: policyId
}

// TODO: simplify code when underlying bug is fixed: https://github.com/Azure/bicep/issues/8782
var policyDefinitionIds_tmp = map(ExistingPolicyInitiativeDefinition.properties.policyDefinitions, policyDefinitions => policyDefinitions.policyDefinitionId)
var policyDefinitionIds = union(policyDefinitionIds_tmp, policyDefinitionIds_tmp)

module PolicyRoles 'collect-policy-roles.bicep' = {
  name: 'CollectPolicyRoles${deploymentNamePostfix}'
  params: {
    policyDefinitionIds: policyDefinitionIds
    deploymentNamePostfix: deploymentNamePostfix
  }
}

var roleDefinitionIds_ = flatten(flatten(PolicyRoles.outputs.policyIds))
var roleDefinitionIds = union(roleDefinitionIds_, roleDefinitionIds_)
var policyInitiativeName = ExistingPolicyInitiativeDefinition.properties.displayName


module PolicyInitiativeAssignment 'policy-assignment.bicep' = {
  name: 'PolicyInitiativeAssignment${deploymentNamePostfix}'
  params: {
    policyName: policyInitiativeName
    location: location
    extraName: extraName
    extraDescription: extraDescription
    policyId: ExistingPolicyInitiativeDefinition.id
    enableMSI: !disableRoleAssignment
    version: version
    parameters: parameters
    enforcementMode: enforcementMode
    nonComplianceMessages: nonComplianceMessages
    notScopes: notScopes
    overrides: overrides
    resourceSelectors: resourceSelectors
  }
}

module RoleAssignments 'role-assignment.bicep' = {
  name: 'RoleAssignments${deploymentNamePostfix}'
  params: {
    policyName: policyInitiativeName
    principalId: PolicyInitiativeAssignment.outputs.principalId
    requiredRoles: roleDefinitionIds
    version: version
  }
  dependsOn: [
    PolicyInitiativeAssignment
    PolicyRoles
  ]
}

output roleDefinitionIds array = roleDefinitionIds
output policyHasRoleDefinitionIds bool = !empty(roleDefinitionIds)
output policyDefinitionIds array = policyDefinitionIds

