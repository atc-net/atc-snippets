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
  [NamingConfig] $namingConfig,

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
$envKeyVaultName        = Get-ResourceName -namingConfig $namingConfig -environmentName $true -suffix 'kv'

# Resource Names
# Microsoft recommended abbreviations https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations
$resourceGroupName      = Get-ResourceGroupName -serviceName $namingConfig.serviceName -systemName $namingConfig.systemName -environmentName $namingConfig.environmentName
$keyVaultName           = Get-ResourceName -namingConfig $namingConfig -suffix 'kv'
$registryName           = Get-ResourceName -namingConfig $namingConfig  -suffix 'cr'
$appServicePlanName     = Get-ResourceName -namingConfig $namingConfig  -suffix 'plan'
$aksClusterName         = Get-ResourceName -namingConfig $namingConfig  -suffix 'aks'
$logAnalyticsName       = Get-ResourceName -namingConfig $namingConfig  -suffix 'log'
$insightsName           = Get-ResourceName -namingConfig $namingConfig  -suffix 'appi'
$cosmosAccountName      = Get-ResourceName -namingConfig $namingConfig  -suffix 'cosmos'
$storageAccountName     = Get-ResourceName -namingConfig $namingConfig  -suffix 'st'
$eventHubNamespaceName  = Get-ResourceName -namingConfig $namingConfig  -suffix 'evhns'
$databricksName         = Get-ResourceName -namingConfig $namingConfig  -suffix 'dbw'
$functionName           = Get-ResourceName -namingConfig $namingConfig  -suffix 'func'
$iotHubName             = Get-ResourceName -namingConfig $namingConfig  -suffix 'iot'
$sqlServerName          = Get-ResourceName -namingConfig $namingConfig  -suffix 'sql'
$sqlServerName          = Get-ResourceName -namingConfig $namingConfig  -suffix 'sql'
$dataLakeName           = Get-ResourceName -namingConfig $namingConfig  -suffix 'dls'
$mlWorkspaceName        = Get-ResourceName -namingConfig $namingConfig  -suffix 'mlw'
$signalRName            = Get-ResourceName -namingConfig $namingConfig  -suffix 'sigr'
$synapseWorkspaceName   = Get-ResourceName -namingConfig $namingConfig  -suffix 'syn'

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
Write-Host "* Function app                     : $functionName" -ForegroundColor White
Write-Host "* IoT Hub                          : $iotHubName" -ForegroundColor White
Write-Host "* SQL server                       : $sqlServerName" -ForegroundColor White
Write-Host "* Data Lake                        : $dataLakeName" -ForegroundColor White
Write-Host "* Maschine Learning workspace      : $mlWorkspaceName" -ForegroundColor White
Write-Host "* SignalR                          : $signalRName" -ForegroundColor White
Write-Host "* Synapse workspace                : $synapseWorkspaceName" -ForegroundColor White
Write-Host "**********************************************************************" -ForegroundColor White

$clientIdName = Get-SpnClientIdName -environmentName $namingConfig.environmentName -systemAbbreviation $namingConfig.systemAbbreviation -serviceAbbreviation $namingConfig.serviceAbbreviation
$objectIdName = Get-SpnObjectIdName -environmentName $namingConfig.environmentName -systemAbbreviation $namingConfig.systemAbbreviation -serviceAbbreviation $namingConfig.serviceAbbreviation
$clientSecretName = Get-SpnClientSecretName -environmentName $namingConfig.environmentName -systemAbbreviation $namingConfig.systemAbbreviation -serviceAbbreviation $namingConfig.serviceAbbreviation
$clientId = Get-KeyVaultSecret -keyVaultName $envKeyVaultName -secretName $clientIdName
$objectId = Get-KeyVaultSecret -keyVaultName $envKeyVaultName -secretName $objectIdName
$clientSecret = Get-KeyVaultSecret -keyVaultName $envKeyVaultName -secretName $clientSecretName

# #############################################################################################
# # Provision Azure Container Registry
# #############################################################################################
# & "$PSScriptRoot\..\acr\deploy.ps1" -resourceGroupName $resourceGroupName -registryName $registryName -resourceTags $resourceTags

# #############################################################################################
# # Provision Azure App Service Plan
# #############################################################################################
# & "$PSScriptRoot\..\appservice\deploy.ps1" -resourceGroupName $resourceGroupName -appServicePlanName $appServicePlanName -resourceTags $resourceTags

#############################################################################################
# Provision Log Analytics and Application Insights
#############################################################################################
# & "$PSScriptRoot\..\monitor\deploy.ps1" -resourceGroupName $resourceGroupName -logAnalyticsName $logAnalyticsName -insightsNam $insightsName -resourceTags $resourceTags
#  $logAnalyticsId = Get-LogAnalyticsId -logAnalyticsName $logAnalyticsName -resourceGroup $resourceGroupName
#  $logAnalyticsKey = Get-LogAnalyticsKey -logAnalyticsName $logAnalyticsName -resourceGroup $resourceGroupName

# #############################################################################################
# # Provision Azure Kubernetes Cluster (AKS)
# #############################################################################################
# & "$PSScriptRoot\..\aks\deploy.ps1" -resourceGroupName $resourceGroupName `
# -environmentName $namingConfig.environmentName -systemName $namingConfig.systemName `
# -aksClusterName $aksClusterName -logAnalyticsId $logAnalyticsId -registryName $registryName `
# -clientId $clientId -clientSecret (ConvertTo-SecureString $clientSecret -AsPlainText -Force) -resourceTags $resourceTags

# #############################################################################################
# # Provision Cosmos Db account
# #############################################################################################
# & "$PSScriptRoot\..\cosmosdb\deploy.ps1" -resourceGroupName $resourceGroupName -cosmosAccountName $cosmosAccountName -resourceTags $resourceTags

# #############################################################################################
# # Provision Storage Account
# #############################################################################################
# & "$PSScriptRoot\..\storage\deploy.ps1" -resourceGroupName $resourceGroupName -storageAccountName $storageAccountName -resourceTags $resourceTags

# #############################################################################################
# # Provision Event Hubs
# #############################################################################################
# & "$PSScriptRoot\..\eventhubs\deploy.ps1" -resourceGroupName $resourceGroupName -eventHubNamespaceName $eventHubNamespaceName -storageAccountName $storageAccountName -resourceTags $resourceTags

# #############################################################################################
# # Provision Databricks
# #############################################################################################
# & "$PSScriptRoot\..\databricks\deploy.ps1" -tenantId $tenantId -resourceGroupName $resourceGroupName `
# -databricksName $databricksName -objectId $objectId -logAnalyticsId $logAnalyticsId -logAnalyticsKey $logAnalyticsKey `
# -clientId $clientId -clientSecret (ConvertTo-SecureString $clientSecret -AsPlainText -Force) `
#  -resourceTags $resourceTags

# #############################################################################################
# # Provision function app
# #############################################################################################
# & "$PSScriptRoot\..\functionapp\deploy.ps1" -resourceGroupName $resourceGroupName `
# -functionName $functionName -storageAccountName $storageAccountName -insightsName $insightsName  `
# -appServicePlanName $appServicePlanName -keyVaultName $keyVaultName -resourceTags $resourceTags

# #############################################################################################
# # Provision IoTHub
# #############################################################################################
# & "$PSScriptRoot\..\iot\deploy.ps1" -resourceGroupName $resourceGroupName `
# -iotHubName $iotHubName -iotHubSasPolicyNameWebApi 'webapiService' -iotHubSasPolicyNameFunctionApp 'functionAppService' `
# -iotHubProcessorConsumerGroupName 'processorfunction' -resourceTags $resourceTags

# #############################################################################################
# # Provision SQL server
# #############################################################################################
# & "$PSScriptRoot\..\sql\deploy.ps1" -resourceGroupName $resourceGroupName `
# -sqlServerName $sqlServerName -dbName 'sqldb' -keyVaultName $keyVaultName `
# -resourceTags $resourceTags

# #############################################################################################
# # Provision Data Lake
# #############################################################################################
# & "$PSScriptRoot\..\datalake\deploy.ps1" -resourceGroupName $resourceGroupName -storageAccountName $dataLakeName -resourceTags $resourceTags

# #############################################################################################
# # Provision Maschine Learning workspace
# #############################################################################################
# & "$PSScriptRoot\..\ml\deploy.ps1" -resourceGroupName $resourceGroupName `
# -mlWorkspaceName $mlWorkspaceName -dataLakeName $storageAccountName `
# -insightsName $insightsName -keyVaultName $keyVaultName -registryName $registryName `
# -resourceTags $resourceTags

# #############################################################################################
# # Provision SignalR
# #############################################################################################
# & "$PSScriptRoot\..\signalR\deploy.ps1" -resourceGroupName $resourceGroupName -signalRName $signalRName -resourceTags $resourceTags

# #############################################################################################
# # Provision Synapse workspace
# #############################################################################################
# & "$PSScriptRoot\..\synapse\deploy.ps1" -resourceGroupName $resourceGroupName `
# -synapseWorkspaceName $synapseWorkspaceName -storageAccountName $dataLakeName -keyVaultName $keyVaultName `
# -resourceTags $resourceTags