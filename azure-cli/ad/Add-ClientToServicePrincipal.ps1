function Add-ClientToServicePrincipal {
  param (
    [Parameter(Mandatory = $true)]
    [EnvironmentConfig] $environmentConfig,

    [Parameter(Mandatory = $true)]
    [NamingConfig] $namingConfig,

    [Parameter(Mandatory = $false)]
    [ValidateSet('api', 'spn', 'app', 'https')]
    [string]
    $appType = "api",

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $applicationId
  )

  # import utility functions
  . "$PSScriptRoot\..\utilities\deploy.naming.ps1"

  $appIdentityId = Get-AppIdentityUri `
    -type $appType `
    -environmentConfig $environmentConfig `
    -namingConfig $namingConfig

  $appId = az ad app list `
      --identifier-uri $appIdentityId `
      --query [-1].id

  $graphApiUri = "https://graph.microsoft.com/v1.0/applications/" + $appId
  $properties = az rest --method get --uri $graphApiUri | ConvertFrom-Json

  $scopeAppId = $properties.api.oauth2PermissionScopes.id
  $body = '{""api"": {""preAuthorizedApplications"": [{""appId"": ""' + $applicationId + '"",""delegatedPermissionIds"": [""' + $scopeAppId + '""]}]}}'

  az rest --method patch --uri $graphApiUri --headers "Content-Type=application/json" --body $body
}