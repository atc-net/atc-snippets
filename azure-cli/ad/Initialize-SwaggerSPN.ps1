function Initialize-SwaggerSpn {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $CompanyHostName,

    [Parameter(Mandatory = $true)]
    [EnvironmentConfig]
    $EnvironmentConfig,

    [Parameter(Mandatory = $true)]
    [NamingConfig]
    $NamingConfig,

    [Parameter(Mandatory = $true)]
    [string[]]
    $RedirectUris,

    [Parameter(Mandatory = $false)]
    [string]
    $ServiceInstance
  )

  # import utility functions
  . "$PSScriptRoot\..\utilities\deploy.naming.ps1"

  $spnAppIdentityId = Get-AppIdentityUri `
    -type "api" `
    -companyHostName $CompanyHostName `
    -environmentConfig $EnvironmentConfig `
    -namingConfig $NamingConfig `
    -serviceInstance $ServiceInstance

  $spnAppIdentityName = Get-AppIdentityDisplayName `
    -type "spn" `
    -environmentConfig $EnvironmentConfig `
    -namingConfig $NamingConfig `
    -serviceInstance "swagger"

  $appId = az ad app list `
    --identifier-uri $spnAppIdentityId `
    --query [0].appId

  Write-Host "Creating Swagger App Registration" -ForegroundColor DarkGreen
  $clientId = az ad app create `
    --display-name $spnAppIdentityName `
    --oauth2-allow-implicit-flow true `
    --query appId

  $objectId = az ad sp show --id $clientId --query objectId

  if (!$objectId) {
    Write-Host "  Creating Service Principal for Swagger App Registration" -ForegroundColor DarkYellow

    $objectId = az ad sp create --id $clientId --query objectId
  }

  Write-Host "  Granting Swagger SPN access to App" -ForegroundColor DarkYellow
  az ad app permission grant --id $clientId --api $appId
  Start-Sleep -Seconds 30 # This ARBITRARY delay time is required otherwise next call to grant admin consent will fail (SOMETIMES!)

  Write-Host "  Giving Admin permission" -ForegroundColor DarkYellow
  az ad app permission admin-consent --id $clientId

  Write-Host "  Setting redirect URIs" -ForegroundColor DarkYellow
  $swaggerAppObjectId = az ad app show --id $clientId --query objectId

  az rest `
    --method PATCH `
    --uri "https://graph.microsoft.com/v1.0/applications/$swaggerAppObjectId" `
    --headers "Content-Type=application/json" `
    --body "{`"spa`":{`"redirectUris`":$(ConvertTo-Json -Compress $RedirectUris)}}"

  Write-Host "  Granting group access to api SPN" -ForegroundColor DarkYellow
  if ($EnvironmentConfig.EnvironmentType -ne "Production") {
    Add-GroupToServicePrincipal -EnvironmentConfig $EnvironmentConfig -NamingConfig $NamingConfig -GroupId "GROUP-ID"
  }
}