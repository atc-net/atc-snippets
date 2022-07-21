function Add-ClientToServicePrincipal {
  param (
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
    [ValidateNotNullOrEmpty()]
    [string]
    $ApplicationId
  )

  # import utility functions
  . "$PSScriptRoot\..\utilities\deploy.naming.ps1"

  $appIdentityId = Get-AppIdentityUri `
    -type $AppType `
    -environmentConfig $EnvironmentConfig `
    -namingConfig $NamingConfig

  $appId = az ad app list `
    --identifier-uri $appIdentityId `
    --query [-1].id

  Write-Host "  Assigning Client pre-authorized access to App Registration" -ForegroundColor DarkYellow

  $graphApiUri = "https://graph.microsoft.com/v1.0/applications/" + $appId
  $properties = az rest --method get --uri $graphApiUri | ConvertFrom-Json

  $scopeAppId = $properties.api.oauth2PermissionScopes.id
  $body = '{""api"": {""preAuthorizedApplications"": [{""appId"": ""' + $ApplicationId + '"",""delegatedPermissionIds"": [""' + $scopeAppId + '""]}]}}'

  az rest --method patch --uri $graphApiUri --headers "Content-Type=application/json" --body $body
}