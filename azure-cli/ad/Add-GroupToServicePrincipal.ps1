function Add-GroupToServicePrincipal {
  param(
    [Parameter(Mandatory = $true)]
    [EnvironmentConfig]
    $EnvironmentConfig,

    [Parameter(Mandatory = $true)]
    [NamingConfig]
    $NamingConfig,

    [Parameter(Mandatory = $false)]
    [ValidateSet('api', 'spn', 'app', 'https')]
    [string]
    $AppType = "api",

    [Parameter(Mandatory = $true)]
    [string]
    $GroupId,

    [Parameter(Mandatory = $false)]
    [string]
    $ServiceInstance
  )

  # import utility functions
  . "$PSScriptRoot\..\utilities\deploy.naming.ps1"

  $spnAppIdentityName = Get-AppIdentityDisplayName `
    -type $AppType `
    -environmentConfig $EnvironmentConfig `
    -namingConfig $NamingConfig `
    -serviceInstance $ServiceInstance

  $objectId = az ad sp list --display-name $spnAppIdentityName --query [0].id

  Write-Host "  Assigning Group access to App Registration" -ForegroundColor DarkYellow -NoNewline

  $existingAssignments = az rest `
    --method GET `
    --url "https://graph.microsoft.com/v1.0/servicePrincipals/$objectId/appRoleAssignedTo" `
    --headers "Content-Type=application/json" ` `
  | ConvertFrom-Json

  Throw-WhenError -output $existingAssignments

  if ($existingAssignments.value.principalId -eq $groupId) {
    Write-Host " -> Group already has access to the Service Principal" -ForegroundColor Cyan
  }
  else {
    Write-Host " -> Grant group access to Service Principal" -ForegroundColor Cyan
    $output = az rest `
      --method POST `
      --url "https://graph.microsoft.com/v1.0/servicePrincipals/$objectId/appRoleAssignedTo" `
      --headers "Content-Type=application/json" `
      --body "{""resourceId"":""$objectId"",""principalId"":""$groupId""}"

    Throw-WhenError -output $output
  }
}