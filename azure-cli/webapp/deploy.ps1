<#
  .SYNOPSIS
  Deploys Azure App Service instance
  .DESCRIPTION
  The deploy.ps1 script deploys an Azure App Service instance using Azure CLI to a resource group in the relevant environment.

  .PARAMETER environmentType
  Specifies the environment type. Staging (DevTest) or Production

  .PARAMETER location
  Specifies the location where the services are deployed. Default is West Europe

  .PARAMETER resourceGroupName
  Specifies the name of the resource group

  .PARAMETER apiName
  Specifies the name of the app service api

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

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $environmentName,

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
  $apiName,

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
. "$PSScriptRoot\..\appservice\get_AppServicePlanId.ps1"

#############################################################################################
# Resource naming section
#############################################################################################
$instrumentationKey = Get-ApplicationInsightsInstrumentationKey $insightsName $resourceGroupName
$appServicePlanId = Get-AppServicePlanId  $appServicePlanName $resourceGroupName

#############################################################################################
# Provision WebApi Service
#############################################################################################
Write-Host "Provision WebApi Service" -ForegroundColor DarkGreen

Write-Host "  Create web app" -ForegroundColor DarkYellow
$output = az webapp create `
  --name $apiName `
  --resource-group $resourceGroupName `
  --plan $appServicePlanId `
  --tags $resourceTags

Throw-WhenError -output $output

Write-Host "  Configure web app" -ForegroundColor DarkYellow
$output = az webapp config set `
  --name $apiName `
  --resource-group $resourceGroupName `
  --min-tls-version '1.2' `
  --use-32bit-worker-process false

Throw-WhenError -output $output

Write-Host "  Allow cross-origin resource sharing (CORS)" -ForegroundColor DarkYellow

$output = az webapp cors remove `
  --name $apiName `
  --resource-group $resourceGroupName `
  --allowed-origins *

Throw-WhenError -output $output

$output = az webapp cors add `
  --name $apiName `
  --resource-group $resourceGroupName `
  --allowed-origins *

Throw-WhenError -output $output

Write-Host "  Apply web app settings" -ForegroundColor DarkYellow
$output = az webapp config appsettings set `
  --name $apiName `
  --resource-group $resourceGroupName `
  --settings `
  ApplicationInsights__InstrumentationKey=$instrumentationKey `
  APPINSIGHTS_INSTRUMENTATIONKEY=$instrumentationKey `
  ServiceOptions__EnvironmentName=$environmentName `
  ServiceOptions__EnvironmentType=$environmentType

Throw-WhenError -output $output

Write-Host "  Grant web app access to key vault" -ForegroundColor DarkYellow
$appPrincipalId = az webapp identity assign `
  --name $apiName `
  --resource-group $resourceGroupName `
  --query principalId

Throw-WhenError -output $appPrincipalId

$output = az keyvault set-policy `
  --name $keyVaultName `
  --resource-group $resourceGroupName `
  --object-id $appPrincipalId `
  --secret-permissions list get

Throw-WhenError -output $output