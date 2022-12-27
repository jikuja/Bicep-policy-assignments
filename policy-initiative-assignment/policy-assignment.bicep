targetScope = 'subscription'

param policyId string
param policyName string
param enableMSI bool
@allowed(['Default', 'DoNotEnforce'])
param enforcementMode string
param location string
param version string
param extraDescription string
param extraName string

// policy properties
param nonComplianceMessages array
param notScopes array
param overrides array
param parameters object
param resourceSelectors array

var description = 'This policy assignment was created automatical by Bicep.\n ${empty(extraDescription) ? '' : '${extraDescription}\n'} Template version: ${version}'

resource PolicyInitiativeAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: guid(subscription().id, policyId, extraName)
  location: location // needed, global does not work
  identity: { 
    type: enableMSI ? 'SystemAssigned' : 'None'
  }
  properties: {
    policyDefinitionId: policyId
    description: description
    displayName: '${policyName}${extraName}'
    enforcementMode: enforcementMode
    metadata: {
      assignedBy: 'Bicep template: ${version}'
    }
    nonComplianceMessages: nonComplianceMessages
    notScopes: notScopes
    overrides: overrides
    parameters: parameters
    resourceSelectors: resourceSelectors
  }
}

output assignmentId string = PolicyInitiativeAssignment.id
output principalId string = enableMSI ? PolicyInitiativeAssignment.identity.principalId : ''
