param (
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $companyHostName,

  [Parameter(Mandatory = $true)]
  [EnvironmentConfig] $environmentConfig,

  [Parameter(Mandatory = $true)]
  [NamingConfig] $namingConfig,

  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string]
  $serviceInstance = ""
)

# import utility functions
. "$PSScriptRoot\..\utilities\deploy.naming.ps1"

$spnAppIdentityId = Get-AppIdentityUri `
  -type "api" `
  -companyHostName $companyHostName `
  -environmentConfig $environmentConfig `
  -namingConfig $namingConfig `
  -serviceInstance $serviceInstance

$spnAppIdentityName = Get-AppIdentityDisplayName `
  -type "spn" `
  -environmentConfig $environmentConfig `
  -namingConfig $namingConfig `
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
  Write-Host "  Creating Service Principal for Swagger App Registration" -ForegroundColor DarkGreen

  $objectId = az ad sp create --id $clientId --query objectId
}

Write-Host "  Granting Swagger SPN access to App" -ForegroundColor DarkGreen
az ad app permission grant --id $clientId --api $appId
Start-Sleep -Seconds 30 # This ARBITRARY delay time is required otherwise next call to grant admin consent will fail (SOMETIMES!)

Write-Host "  Giving Admin permission" -ForegroundColor DarkGreen
az ad app permission admin-consent --id $clientId

Write-Host "  Setting redirect URIs" -ForegroundColor DarkGreen
$swaggerAppObjectId = az ad app show --id $clientId --query objectId

$redirectUri = "https://$($namingConfig.ServiceAbbreviation).$($environmentConfig.EnvironmentName).$companyHostName/swagger/oauth2-redirect.html"

$redirectUris = "[\""$($redirectUri.ToLower())\""]"

if ($environmentConfig.environmentType -ne "Production") {
  $redirectUris = "[\""$($redirectUri.ToLower())\"", \""https://localhost:5001/swagger/oauth2-redirect.html\""]"
}

az rest `
  --method PATCH `
  --uri "https://graph.microsoft.com/v1.0/applications/$swaggerAppObjectId" `
  --headers "Content-Type=application/json" `
  --body "{\""spa\"":{\""redirectUris\"":$redirectUris}}"

Write-Host "  Granting group access to api SPN" -ForegroundColor DarkGreen
if ($environmentConfig.environmentType -ne "Production") {
  Add-GroupToServicePrincipal -environmentConfig $environmentConfig -namingConfig $namingConfig -groupId "GROUP-ID"
}