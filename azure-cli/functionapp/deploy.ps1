<#
  .SYNOPSIS
  Deploys Azure Function app

  .DESCRIPTION
  The deploy.ps1 script deploys an Azure Function app instance using the CLI tool to a resource group in the relevant environment.

  .PARAMETER environmentType
  Specifies the environment type. Staging (DevTest) or production

  .PARAMETER location
  Specifies the location where the services are deployed. Default is West Europe

  .PARAMETER resourceGroupName
  Specifies the name of the resource group

  .PARAMETER functionName
  Specifies the name of the Function app

  .PARAMETER storageAccountName
  Specifies the name of the storage account

  .PARAMETER insightsName
  Specifies the name of the application insights

  .PARAMETER appServicePlanName
  Specifies the name of the app service plan

  .PARAMETER keyVaultName
  Specifies the name of the key vault

  .PARAMETER resourceTags
  Specifies the tag elements that will be used to tag the deployed services

  .INPUTS
  None. You cannot pipe objects to deploy.ps1.

  .OUTPUTS
  None. deploy.ps1 does not generate any output.
#>
param (
  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [ValidateSet('DevTest', 'Production')]
  [string]
  $environmentType = "DevTest",

  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string]
  $location = "westeurope",

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
  [string[]] $resourceTags = @()
)

#############################################################################################
# Configure names and options
#############################################################################################
# import utility functions
. "$PSScriptRoot\..\monitor\get_ApplicationInsights_InstrumentationKey.ps1"
. "$PSScriptRoot\..\storage\get_StorageAccountId.ps1"
. "$PSScriptRoot\..\appservice\get_AppServicePlanId.ps1"

#############################################################################################
# Resource naming section
#############################################################################################
$storageAccountId = Get-StorageAccountId  $storageAccountName $resourceGroupName
$instrumentationKey = Get-ApplicationInsightsInstrumentationKey $insightsName $resourceGroupName
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
--app-insights-key $instrumentationKey `
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