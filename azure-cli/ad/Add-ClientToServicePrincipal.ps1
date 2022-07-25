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
  . "$PSScriptRoot\..\utilities\deploy.utilities.ps1"

  $appIdentityId = Get-AppIdentityUri `
    -type $AppType `
    -environmentConfig $EnvironmentConfig `
    -namingConfig $NamingConfig

  $appId = az ad app list `
    --identifier-uri $appIdentityId `
    --query [-1].id `
    --out tsv

  Throw-WhenError -output $appId

  Write-Host "  Assigning Client pre-authorized access to App Registration" -ForegroundColor DarkYellow -NoNewline

  $graphApiUri = "https://graph.microsoft.com/v1.0/applications/$appId"
  $properties = az rest `
    --method GET `
    --uri $graphApiUri `
    --headers "Content-Type=application/json" `
    | ConvertFrom-Json

  Throw-WhenError -output $properties

  $body = @{
    api = @{
      preAuthorizedApplications = @(
        @{
          appId = $ApplicationId
          delegatedPermissionIds = @( $properties.api.oauth2PermissionScopes.id )
        }
      )
    }
  }

  $output =  az rest `
    --method PATCH `
    --uri $graphApiUri `
    --headers "Content-Type=application/json" `
    --body (ConvertTo-RequestJson $body -Depth 5)

    Throw-WhenError -output $output
    Write-Host " -> Pre-authorization assigned" -ForegroundColor Cyan
}