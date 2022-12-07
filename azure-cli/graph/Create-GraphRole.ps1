function Create-GraphRole {

  param (
    [Parameter(Mandatory = $true)]
    [string]
    $principalId,
    [Parameter(Mandatory = $true)]
    [string]
    $roleDefinitionId
  )
  $helpVar = "@odata.type"

  return Invoke-GraphRestRequest -method "post" -url "roleManagement/directory/roleAssignments" -body @{$helpVar = "#microsoft.graph.unifiedRoleAssignment"; principalId = $principalId; roleDefinitionId = $roleDefinitionId; DirectoryScopeId = "/" }
}
