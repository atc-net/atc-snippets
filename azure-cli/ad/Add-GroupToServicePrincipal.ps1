function Add-GroupToServicePrincipal(
  [Parameter(Mandatory = $true)]
  [EnvironmentConfig]
  $EnvironmentConfig,

  [Parameter(Mandatory = $true)]
  [NamingConfig]
  $NamingConfig,

  [Parameter(Mandatory = $true)]
  [string]
  $GroupId,

  [Parameter(Mandatory = $false)]
  [string]
  $ServiceInstance
)
{
  # import utility functions
  . "$PSScriptRoot\..\utilities\deploy.naming.ps1"

  $spnAppIdentityName = Get-AppIdentityDisplayName `
    -type "api" `
    -environmentConfig $EnvironmentConfig `
    -namingConfig $NamingConfig `
    -serviceInstance $ServiceInstance

  $objectId = az ad sp list --display-name $spnAppIdentityName --query [0].objectId

  Write-Host "Grant group access to Service Principal" -ForegroundColor DarkGreen
  az rest `
    --method POST `
    --url https://graph.microsoft.com/v1.0/servicePrincipals/$objectId/appRoleAssignedTo `
    --headers "Content-Type=application/json" `
    --body "{`"resourceId`":`"$objectId`",`"principalId`":`"$GroupId`"}"
}