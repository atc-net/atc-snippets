param (
  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [ValidateSet('DevTest', 'Production')]
  [string]
  $environmentType = "DevTest",

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $resourceGroupName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $functionName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $storageAccountName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $insightsName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $appServicePlanName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $keyVaultName,

  [Parameter(Mandatory = $false)]
  [string]
  $location = "westeurope",

  [Parameter(Mandatory = $false)]
  [string[]]
  $resourceTags = @()
)

#############################################################################################
# Configure names and options
#############################################################################################
# import utility functions
. "$PSScriptRoot\..\storage\get_StorageAccountId.ps1"
. "$PSScriptRoot\..\appservice\get_AppServicePlanId.ps1"

#############################################################################################
# Resource naming section
#############################################################################################
$storageAccountId = Get-StorageAccountId  $storageAccountName $resourceGroupName
$appServicePlanId = Get-AppServicePlanId  $appServicePlanName $resourceGroupName

#############################################################################################
# Provision function app
#############################################################################################
Write-Host "Provision function app" -ForegroundColor DarkGreen

Write-Host "  Creating function app" -ForegroundColor DarkYellow
$output = az functionapp create `
  --name $functionName `
  --resource-group $resourceGroupName `
  --storage-account $storageAccountId `
  --app-insights $insightsName `
  --plan $appServicePlanId `
  --runtime dotnet `
  --functions-version 3 `
  --tags $resourceTags

Throw-WhenError -output $output

Write-Host "  Grant keyvault access to function app" -ForegroundColor DarkYellow
$functionPrincipalId = az functionapp identity assign `
  --name $functionName `
  --resource-group $resourceGroupName `
  --query principalId

Throw-WhenError -output $appPrincipalId

$output = az keyvault set-policy `
  --name $keyVaultName `
  --resource-group $resourceGroupName `
  --object-id $functionPrincipalId `
  --secret-permissions list get

Throw-WhenError -output $output

Write-Host "  Configuring function app" -ForegroundColor DarkYellow
$output = az functionapp config set `
  --name $functionName `
  --resource-group $resourceGroupName `
  --min-tls-version '1.2' `
  --use-32bit-worker-process false

Throw-WhenError -output $output

Write-Host "  Applying function app settings" -ForegroundColor DarkYellow

$output = az functionapp config appsettings set `
  --name $functionName `
  --resource-group $resourceGroupName `
  --settings `
  FunctionOptions__EnvironmentName=$environmentName `
  FunctionOptions__EnvironmentType=$environmentType

Throw-WhenError -output $output