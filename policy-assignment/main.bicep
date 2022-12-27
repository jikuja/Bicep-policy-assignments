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

// policy properties
param nonComplianceMessages array = []
param notScopes array = []
param overrides array = []
@description('Policy definition parameters')
param parameters object = {}
param resourceSelectors array = []

var version = '2022-12-18'

resource ExistingPolicyDefinition 'Microsoft.Authorization/policyDefinitions@2021-06-01' existing = {
  scope: tenant()
  name: policyId
}

// TODO: fix when underlying bug is fixed: https://github.com/Azure/bicep/issues/8782
var then = string(ExistingPolicyDefinition.properties.policyRule.then)
var policyHasRoleDefinitionIds = contains(then, 'roleDefinitionIds')
var roleDefinitionIds = policyHasRoleDefinitionIds ? ExistingPolicyDefinition.properties.policyRule.then.details.roleDefinitionIds : []

var policyName = ExistingPolicyDefinition.properties.displayName
var roleDefinitionParameters = ExistingPolicyDefinition.properties.parameters

module PolicyAssignment 'policy-assignment.bicep' = {
  name: 'PolicyAssignment${deploymentNamePostfix}'
  params: {
    policyName: policyName
    location: location
    extraName: extraName
    extraDescription: extraDescription
    policyId: ExistingPolicyDefinition.id
    enableMSI: policyHasRoleDefinitionIds
    version: version
    parameters: parameters
    enforcementMode: enforcementMode
    nonComplianceMessages: nonComplianceMessages
    notScopes: notScopes
    overrides: overrides
    resourceSelectors: resourceSelectors
  }
}

// This has internal condition with roleDefinitionIds
module RoleAssignments 'role-assignment.bicep' = if (!disableRoleAssignment) {
  name: 'RoleAssignments${deploymentNamePostfix}'
  params: {
    policyId: policyId
    policyName: policyName
    principalId: PolicyAssignment.outputs.principalId
    requiredRoles: roleDefinitionIds
    version: version
  }
  dependsOn: [
    PolicyAssignment
    ExistingPolicyDefinition
  ]
}

output roleDefinitionIds array = roleDefinitionIds
output policyHasRoleDefinitionIds bool = policyHasRoleDefinitionIds
output policyName string = policyName
output roleDefinitionParameters object = roleDefinitionParameters

// TODO:
// * multiple deployments into one scope
// * naming
//   * persist deployment

// Naming limitations
// deployment name:
// * 1-64
// * Alphanumerics, underscores, parentheses, hyphens, and periods.
