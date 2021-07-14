<#
  .SYNOPSIS
  Deploys Azure services with the Azure CLI tool

  .DESCRIPTION
  The deploy.ps1 script deploys Azure service using the CLI tool to a resource group in the relevant environment.

  .PARAMETER environmentType
  Specifies the environment type. Staging (DevTest) or production

  .PARAMETER location
  Specifies the location where the services are deployed. Default is West Europe

  .PARAMETER namingConfig
  Specifies the configuration element used to build the resource names for the resource group and the services

  .PARAMETER resourceTags
  Specifies the tag elements that will be used to tag the deployed services

  .INPUTS
  None. You cannot pipe objects to deploy.ps1.

  .OUTPUTS
  None. Udeploy.ps1 does not generate any output.

  .EXAMPLE
  PS> .\deploy.ps1 -environmentType DevTest -environmentName Dev -namingConfig [PSCustomObject]@{companyAbbreviation = "xxx" systemName = "xxx" systemAbbreviation  = "xxx" serviceName = "xxx" serviceAbbreviation = "xxx"}
#>
param (
  [Parameter(Mandatory = $false)]
  [string] $tenantId,

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
  [PSCustomObject] $namingConfig = @(
    environmentName = 'xxx'
    companyAbbreviation = 'xxx'
    systemName = 'xxx'
    systemAbbreviation = 'xxx'
    serviceName = 'xxx'
    serviceAbbreviation = 'xxx'
  ),

  [Parameter(Mandatory = $false)]
  [string[]] $resourceTags = @()
)

#############################################################################################
# Configure names and options
#############################################################################################
Write-Host "Initialize deployment" -ForegroundColor DarkGreen

# import utility functions
. "$PSScriptRoot\utilities\deploy.utilities.ps1"
. "$PSScriptRoot\utilities\deploy.naming.ps1"
. "$PSScriptRoot\..\monitor\get_LogAnalyticsId.ps1"
. "$PSScriptRoot\..\monitor\get_LogAnalyticsKey.ps1"
. "$PSScriptRoot\..\keyvault\get_KeyVaultSecret.ps1"

# Install required extensions
. "$PSScriptRoot\extensions.ps1"

if (!$tenantId) {
  $tenantId = (az account show --query tenantId).Replace('"','')
}

#############################################################################################
# Resource naming section
#############################################################################################

# Environment Resource Names
$envResourceGroupName   = Get-ResourceGroupName -systemName $namingConfig.systemName -environmentName $namingConfig.environmentName
$envKeyVaultName        = Get-ResourceName -companyAbbreviation $namingConfig.companyAbbreviation -systemAbbreviation $namingConfig.systemAbbreviation -environmentName $namingConfig.environmentName -suffix "kv"

# Resource Names
$resourceGroupName      = Get-ResourceGroupName -serviceName $namingConfig.serviceName -systemName $namingConfig.systemName -environmentName $namingConfig.environmentName
$keyVaultName           = Get-ResourceName -serviceAbbreviation $namingConfig.serviceAbbreviation -companyAbbreviation $namingConfig.companyAbbreviation -systemAbbreviation $namingConfig.systemAbbreviation -environmentName $namingConfig.environmentName -suffix 'kv'
$registryName           = Get-ResourceName -serviceAbbreviation $namingConfig.serviceAbbreviation -companyAbbreviation $namingConfig.companyAbbreviation -systemAbbreviation $namingConfig.systemAbbreviation -environmentName $namingConfig.environmentName -suffix 'cr'
$appServicePlanName     = Get-ResourceName -serviceAbbreviation $namingConfig.serviceAbbreviation -companyAbbreviation $namingConfig.companyAbbreviation -systemAbbreviation $namingConfig.systemAbbreviation -environmentName $namingConfig.environmentName -suffix 'plan'
$aksClusterName         = Get-ResourceName -serviceAbbreviation $namingConfig.serviceAbbreviation -companyAbbreviation $namingConfig.companyAbbreviation -systemAbbreviation $namingConfig.systemAbbreviation -environmentName $namingConfig.environmentName -suffix 'aks'
$logAnalyticsName       = Get-ResourceName -serviceAbbreviation $namingConfig.serviceAbbreviation -companyAbbreviation $namingConfig.companyAbbreviation -systemAbbreviation $namingConfig.systemAbbreviation -environmentName $namingConfig.environmentName -suffix 'log'
$insightsName           = Get-ResourceName -serviceAbbreviation $namingConfig.serviceAbbreviation -companyAbbreviation $namingConfig.companyAbbreviation -systemAbbreviation $namingConfig.systemAbbreviation -environmentName $namingConfig.environmentName -suffix 'appi'
$cosmosAccountName      = Get-ResourceName -serviceAbbreviation $namingConfig.serviceAbbreviation -companyAbbreviation $namingConfig.companyAbbreviation -systemAbbreviation $namingConfig.systemAbbreviation -environmentName $namingConfig.environmentName -suffix 'cosmos'
$storageAccountName     = Get-ResourceName -serviceAbbreviation $namingConfig.serviceAbbreviation -companyAbbreviation $namingConfig.companyAbbreviation -systemAbbreviation $namingConfig.systemAbbreviation -environmentName $namingConfig.environmentName -suffix 'st'
$eventHubNamespaceName  = Get-ResourceName -serviceAbbreviation $namingConfig.serviceAbbreviation -companyAbbreviation $namingConfig.companyAbbreviation -systemAbbreviation $namingConfig.systemAbbreviation -environmentName $namingConfig.environmentName -suffix 'evhns'
$databricksName         = Get-ResourceName -serviceAbbreviation $namingConfig.serviceAbbreviation -companyAbbreviation $namingConfig.companyAbbreviation -systemAbbreviation $namingConfig.systemAbbreviation -environmentName $namingConfig.environmentName -suffix 'dbw'

# Write setup

Write-Host "**********************************************************************" -ForegroundColor White
Write-Host "* Environment name                 : $($namingConfig.environmentName)" -ForegroundColor White
Write-Host "* Env. resource group name         : $envResourceGroupName" -ForegroundColor White
Write-Host "* Env. key vault                   : $envKeyVaultName" -ForegroundColor White
Write-Host "* Resource group name              : $resourceGroupName" -ForegroundColor White
Write-Host "* Key vault name                   : $keyVaultName" -ForegroundColor White
Write-Host "* Container registry               : $registryName" -ForegroundColor White
Write-Host "* App service plan                 : $appServicePlanName" -ForegroundColor White
Write-Host "* Kubernetes cluster               : $aksClusterName" -ForegroundColor White
Write-Host "* Log analytics                    : $logAnalyticsName" -ForegroundColor White
Write-Host "* Application insights             : $insightsName" -ForegroundColor White
Write-Host "* Cosmos database                  : $cosmosAccountName" -ForegroundColor White
Write-Host "* Storage account                  : $storageAccountName" -ForegroundColor White
Write-Host "* Event hub namespace              : $eventHubNamespaceName" -ForegroundColor White
Write-Host "* Databricks workspace             : $databricksName" -ForegroundColor White
Write-Host "**********************************************************************" -ForegroundColor White

$clientIdName = Get-SpnClientIdName -environmentName $namingConfig.environmentName -systemAbbreviation $namingConfig.systemAbbreviation -serviceAbbreviation $namingConfig.serviceAbbreviation
$objectIdName = Get-SpnObjectIdName -environmentName $namingConfig.environmentName -systemAbbreviation $namingConfig.systemAbbreviation -serviceAbbreviation $namingConfig.serviceAbbreviation
$clientSecretName = Get-SpnClientSecretName -environmentName $namingConfig.environmentName -systemAbbreviation $namingConfig.systemAbbreviation -serviceAbbreviation $namingConfig.serviceAbbreviation
$clientId = Get-KeyVaultSecret -keyVaultName $envKeyVaultName -secretName $clientIdName
$objectId = Get-KeyVaultSecret -keyVaultName $envKeyVaultName -secretName $objectIdName
$clientSecret = Get-KeyVaultSecret -keyVaultName $envKeyVaultName -secretName $clientSecretName

#############################################################################################
# Provision Azure Container Registry
#############################################################################################
#& "$PSScriptRoot\..\acr\deploy.ps1" -resourceGroupName $resourceGroupName -registryName $registryName -resourceTags $resourceTags

#############################################################################################
# Provision Azure App Service Plan
#############################################################################################
#& "$PSScriptRoot\..\appservice\deploy.ps1" -resourceGroupName $resourceGroupName -appServicePlanName $appServicePlanName -resourceTags $resourceTags

#############################################################################################
# Provision Log Analytics and Application Insights
#############################################################################################
#& "$PSScriptRoot\..\monitor\deploy.ps1" -resourceGroupName $resourceGroupName -logAnalyticsName $logAnalyticsName -insightsNam $insightsName -resourceTags $resourceTags
$logAnalyticsId = Get-LogAnalyticsId -logAnalyticsName $logAnalyticsName -resourceGroup $resourceGroupName
$logAnalyticsKey = Get-LogAnalyticsKey -logAnalyticsName $logAnalyticsName -resourceGroup $resourceGroupName

#############################################################################################
# Provision Azure Kubernetes Cluster (AKS)
#############################################################################################
# & "$PSScriptRoot\..\aks\deploy.ps1" -resourceGroupName $resourceGroupName `
# -environmentName $namingConfig.environmentName -systemName $namingConfig.systemName `
# -aksClusterName $aksClusterName -logAnalyticsId $logAnalyticsId -registryName $registryName `
# -clientId $clientId -clientSecret (ConvertTo-SecureString $clientSecret -AsPlainText -Force) -resourceTags $resourceTags

#############################################################################################
# Provision Cosmos Db account
#############################################################################################
#& "$PSScriptRoot\..\cosmosdb\deploy.ps1" -resourceGroupName $resourceGroupName -cosmosAccountName $cosmosAccountName -resourceTags $resourceTags

#############################################################################################
# Provision Storage Account
#############################################################################################
#& "$PSScriptRoot\..\storage\deploy.ps1" -resourceGroupName $resourceGroupName -storageAccountName $storageAccountName -resourceTags $resourceTags

#############################################################################################
# Provision Event Hubs
#############################################################################################
#& "$PSScriptRoot\..\eventhubs\deploy.ps1" -resourceGroupName $resourceGroupName -eventHubNamespaceName $eventHubNamespaceName -storageAccountName $storageAccountName -resourceTags $resourceTags

#############################################################################################
# Databricks
#############################################################################################
& "$PSScriptRoot\..\databricks\deploy.ps1" -tenantId $tenantId -resourceGroupName $resourceGroupName `
-databricksName $databricksName -objectId $objectId -logAnalyticsId $logAnalyticsId -logAnalyticsKey $logAnalyticsKey `
-clientId $clientId -clientSecret (ConvertTo-SecureString $clientSecret -AsPlainText -Force) `
 -resourceTags $resourceTags