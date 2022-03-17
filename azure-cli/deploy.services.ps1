param (
  [Parameter(Mandatory = $true)]
  [EnvironmentConfig]
  $environmentConfig,

  [Parameter(Mandatory = $true)]
  [NamingConfig]
  $namingConfig,

  [Parameter(Mandatory = $false)]
  [string[]]
  $resourceTags = @()
)

#############################################################################################
# Configure names and options
#############################################################################################
Write-Host "Initialize deployment" -ForegroundColor DarkGreen

# import utility functions
. "$PSScriptRoot\appservice\Provision-AppServicePlan.ps1"
. "$PSScriptRoot\utilities\deploy.utilities.ps1"
. "$PSScriptRoot\utilities\deploy.naming.ps1"
. "$PSScriptRoot\monitor\Provision-ApplicationInsights.ps1"
. "$PSScriptRoot\monitor\Provision-LogAnalyticsWorkspace.ps1"
. "$PSScriptRoot\keyvault\get_KeyVaultSecret.ps1"
. "$PSScriptRoot\storage\get_StorageAccountKey.ps1"
. "$PSScriptRoot\iot\add_IotHubToDataLakeRoutingEndpoint.ps1"
. "$PSScriptRoot\iot\get_IoTHubServiceFunctionEventHubEndpointConnection.ps1"
. "$PSScriptRoot\cosmosdb\get_CosmosConnectionString.ps1"
. "$PSScriptRoot\signalr\get_SignalRConnectionString.ps1"

# Install required extensions
. "$PSScriptRoot\extensions.ps1"

$tenantId = (az account show --query tenantId).Replace('"','')

#############################################################################################
# Resource naming section
#############################################################################################
# Environment Resource Names
$envResourceGroupName   = Get-ResourceGroupName -systemName $namingConfig.SystemName -environmentName $environmentConfig.EnvironmentName
$envKeyVaultName        = Get-ResourceName -environmentConfig $environmentConfig -namingConfig $namingConfig -environmentName $true

# Resource Names
$resourceGroupName      = Get-ResourceGroupName -serviceName $namingConfig.ServiceName -systemName $namingConfig.SystemName -environmentName $environmentConfig.EnvironmentName
$keyVaultName           = Get-ResourceName -environmentConfig $environmentConfig -namingConfig $namingConfig
$registryName           = Get-ResourceName -environmentConfig $environmentConfig -namingConfig $namingConfig
$appServicePlanName     = Get-ResourceName -environmentConfig $environmentConfig -namingConfig $namingConfig
$aksClusterName         = Get-ResourceName -environmentConfig $environmentConfig -namingConfig $namingConfig
$logAnalyticsName       = Get-ResourceName -environmentConfig $environmentConfig -namingConfig $namingConfig
$insightsName           = Get-ResourceName -environmentConfig $environmentConfig -namingConfig $namingConfig
$cosmosAccountName      = Get-ResourceName -environmentConfig $environmentConfig -namingConfig $namingConfig
$storageAccountName     = Get-ResourceName -environmentConfig $environmentConfig -namingConfig $namingConfig
$eventHubNamespaceName  = Get-ResourceName -environmentConfig $environmentConfig -namingConfig $namingConfig
$databricksName         = Get-ResourceName -environmentConfig $environmentConfig -namingConfig $namingConfig
$functionName           = Get-ResourceName -environmentConfig $environmentConfig -namingConfig $namingConfig -suffix 'func'
$iotHubName             = Get-ResourceName -environmentConfig $environmentConfig -namingConfig $namingConfig
$dpsName                = Get-ResourceName -environmentConfig $environmentConfig -namingConfig $namingConfig
$sqlServerName          = Get-ResourceName -environmentConfig $environmentConfig -namingConfig $namingConfig
$sqlServerName          = Get-ResourceName -environmentConfig $environmentConfig -namingConfig $namingConfig
$dataLakeName           = Get-ResourceName -environmentConfig $environmentConfig -namingConfig $namingConfig -suffix 'dls'
$mlWorkspaceName        = Get-ResourceName -environmentConfig $environmentConfig -namingConfig $namingConfig
$signalRName            = Get-ResourceName -environmentConfig $environmentConfig -namingConfig $namingConfig
$synapseWorkspaceName   = Get-ResourceName -environmentConfig $environmentConfig -namingConfig $namingConfig
$timeseriesinsightsName = Get-ResourceName -environmentConfig $environmentConfig -namingConfig $namingConfig
$apiName                = Get-ResourceName -environmentConfig $environmentConfig -namingConfig $namingConfig -suffix 'api'
$serviceBusName         = Get-ResourceName -environmentConfig $environmentConfig -namingConfig $namingConfig

# Write setup

Write-Host "**********************************************************************" -ForegroundColor White
Write-Host "* Environment name                 : $($environmentConfig.environmentName)" -ForegroundColor White
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
Write-Host "* Device Provisioning Service      : $dpsName" -ForegroundColor White
Write-Host "* SQL server                       : $sqlServerName" -ForegroundColor White
Write-Host "* Data Lake                        : $dataLakeName" -ForegroundColor White
Write-Host "* Machine Learning workspace       : $mlWorkspaceName" -ForegroundColor White
Write-Host "* SignalR                          : $signalRName" -ForegroundColor White
Write-Host "* Synapse workspace                : $synapseWorkspaceName" -ForegroundColor White
Write-Host "* Time Series Insights             : $timeseriesinsightsName" -ForegroundColor White
Write-Host "* Web App                          : $apiName" -ForegroundColor White
Write-Host "* Service Bus Namespace            : $serviceBusName" -ForegroundColor White
Write-Host "**********************************************************************" -ForegroundColor White

$clientIdName = Get-SpnClientIdName -environmentConfig $environmentConfig -namingConfig $namingConfig
$objectIdName = Get-SpnObjectIdName -environmentConfig $environmentConfig -namingConfig $namingConfig
$clientSecretName = Get-SpnClientSecretName -environmentConfig $environmentConfig -namingConfig $namingConfig
$clientId = Get-KeyVaultSecret -keyVaultName $envKeyVaultName -secretName $clientIdName
$objectId = Get-KeyVaultSecret -keyVaultName $envKeyVaultName -secretName $objectIdName
$clientSecret = Get-KeyVaultSecret -keyVaultName $envKeyVaultName -secretName $clientSecretName

#############################################################################################
# Initialize Azure Container Registry
#############################################################################################
& "$PSScriptRoot\acr\deploy.ps1" `
  -resourceGroupName $resourceGroupName `
  -registryName $registryName `
  -resourceTags $resourceTags

#############################################################################################
# Initialize Azure App Service Plan
#############################################################################################
$appServiceSku = 'S1'
if ($environmentConfig.EnvironmentType -eq 'Production') {
  $appServiceSku = 'P1V2'
}

$appServicePlanId = Provision-AppServicePlan `
  -Name $appServicePlanName `
  -Sku $appServiceSku `
  -ResourceGroupName $resourceGroupName `
  -Location $environmentConfig.Location `
  -ResourceTags $resourceTags

############################################################################################
# Initialize Log Analytics and Application Insights
############################################################################################
$logAnalyticsId = Provision-LogAnalyticsWorkspace `
  -LogAnalyticsName $logAnalyticsName `
  -ResourceGroupName $resourceGroupName `
  -Location $environmentConfig.Location `
  -ResourceTags $resourceTags

$logAnalyticsKey = Get-LogAnalyticsKey `
  -LogAnalyticsName $logAnalyticsName `
  -ResourceGroup $resourceGroupName

$instrumentationKey = Provision-ApplicationInsights `
  -Name $insightsName `
  -LogAnalyticsId $logAnalyticsId `
  -ResourceGroupName $resourceGroupName `
  -Location $environmentConfig.Location `
  -ResourceTags $resourceTags

#############################################################################################
# Initialize Azure Kubernetes Cluster (AKS)
#############################################################################################
& "$PSScriptRoot\aks\deploy.ps1" `
  -resourceGroupName $resourceGroupName `
  -aksClusterName $aksClusterName `
  -logAnalyticsId $logAnalyticsId `
  -registryName $registryName `
  -clientId $clientId `
  -clientSecret (ConvertTo-SecureString $clientSecret -AsPlainText -Force) `
  -resourceTags $resourceTags

#############################################################################################
# Initialize Cosmos Db account
#############################################################################################
& "$PSScriptRoot\cosmosdb\deploy.ps1" `
  -resourceGroupName $resourceGroupName `
  -cosmosAccountName $cosmosAccountName `
  -resourceTags $resourceTags

#############################################################################################
# Initialize Storage Account
#############################################################################################
& "$PSScriptRoot\storage\deploy.ps1" `
  -resourceGroupName $resourceGroupName `
  -storageAccountName $storageAccountName `
  -resourceTags $resourceTags

#############################################################################################
# Initialize Event Hubs
#############################################################################################
& "$PSScriptRoot\eventhubs\deploy.ps1" `
  -resourceGroupName $resourceGroupName `
  -eventHubNamespaceName $eventHubNamespaceName `
  -storageAccountName $storageAccountName `
  -resourceTags $resourceTags

#############################################################################################
# Initialize Databricks
#############################################################################################
& "$PSScriptRoot\databricks\deploy.ps1" `
  -tenantId $tenantId `
  -resourceGroupName $resourceGroupName `
  -databricksName $databricksName `
  -objectId $objectId `
  -logAnalyticsId $logAnalyticsId `
  -logAnalyticsKey $logAnalyticsKey `
  -clientId $clientId -clientSecret (ConvertTo-SecureString $clientSecret -AsPlainText -Force) `
  -resourceTags $resourceTags

#############################################################################################
# Initialize function app
#############################################################################################
& "$PSScriptRoot\functionapp\deploy.ps1" `
  -resourceGroupName $resourceGroupName `
  -functionName $functionName `
  -storageAccountName $storageAccountName `
  -insightsName $insightsName  `
  -appServicePlanName $appServicePlanName `
  -keyVaultName $keyVaultName `
  -resourceTags $resourceTags

#############################################################################################
# Initialize IotHub & DPS
#############################################################################################
$iotHubSku = 'S1'
if ($environmentConfig.EnvironmentType -eq 'Production') {
  $iotHubSku = 'S2'
}

Initialize-IotHub `
  -Name $iotHubName `
  -ResourceGroupName $resourceGroupName `
  -Sku $iotHubSku `
  -NumberOfUnits 1 `
  -PartitionCount 4 `
  -RetentionTimeInDays 7 `
  -CloudToDeviceMaxAttempts 10 `
  -CloudToDeviceMessageLifeTimeInHours 1 `
  -FeedbackQueueMaximumDeliveryCount 10 `
  -FeedbackQueueLockDurationInSeconds 60 `
  -FeedbackQueueTimeToLiveInHours 1 `
  -Location $environmentConfig.Location `
  -ResourceTags $resourceTags

Initialize-DeviceProvisioningService `
  -Name $dpsName `
  -ResourceGroupName $resourceGroupName `
  -Sku 'S1' `
  -NumberOfUnits 1 `
  -AllocationPolicy 'Hashed' `
  -Location $environmentConfig.Location `
  -ResourceTags $resourceTags

Connect-IotHubWithDeviceProvisioningService `
  -IotHubName $iotHubName `
  -DeviceProvisioningServiceName $dpsName `
  -ResourceGroupName $resourceGroupName

#############################################################################################
# Initialize SQL server
#############################################################################################
& "$PSScriptRoot\sql\deploy.ps1" `
  -resourceGroupName $resourceGroupName `
  -sqlServerName $sqlServerName `
  -dbName 'sqldb' `
  -keyVaultName $keyVaultName `
  -resourceTags $resourceTags

#############################################################################################
# Initialize Data Lake
#############################################################################################
& "$PSScriptRoot\datalake\deploy.ps1" `
  -resourceGroupName $resourceGroupName `
  -dataLakeName $dataLakeName `
  -resourceTags $resourceTags

#############################################################################################
# Initialize Machine Learning workspace
#############################################################################################
& "$PSScriptRoot\ml\deploy.ps1" `
  -resourceGroupName $resourceGroupName `
  -mlWorkspaceName $mlWorkspaceName `
  -dataLakeName $storageAccountName `
  -insightsName $insightsName `
  -keyVaultName $keyVaultName `
  -registryName $registryName `
  -resourceTags $resourceTags

#############################################################################################
# Initialize SignalR
#############################################################################################
& "$PSScriptRoot\signalR\deploy.ps1" `
  -resourceGroupName $resourceGroupName `
  -signalRName $signalRName `
  -serviceMode 'Default' `
  -resourceTags $resourceTags

#############################################################################################
# Initialize Synapse workspace
#############################################################################################
& "$PSScriptRoot\synapse\deploy.ps1" `
  -resourceGroupName $resourceGroupName `
  -synapseWorkspaceName $synapseWorkspaceName `
  -storageAccountName $dataLakeName `
  -keyVaultName $keyVaultName `
  -resourceTags $resourceTags

#############################################################################################
# Time Series Insights
#############################################################################################
& "$PSScriptRoot\tsi\deploy.ps1" `
  -resourceGroupName $resourceGroupName `
  -timeseriesinsightsName $timeseriesinsightsName `
  -storageAccountName $dataLakeName `
  -eventHubNamespaceName $eventHubNamespaceName `
  -resourceTags $resourceTags

#############################################################################################
# Initialize function app api
#############################################################################################
& "$PSScriptRoot\webapp\deploy.ps1" `
  -resourceGroupName $resourceGroupName `
  -environmentName $environmentConfig.EnvironmentName `
  -apiName $apiName `
  -insightsName $insightsName  `
  -appServicePlanName $appServicePlanName `
  -keyVaultName $keyVaultName `
  -resourceTags $resourceTags

#############################################################################################
# Initialize Service Bus namespace
#############################################################################################
& "$PSScriptRoot\servicebus\deploy.ps1" `
  -resourceGroupName $resourceGroupName `
  -serviceBusName $serviceBusName `
  -logAnalyticsId $logAnalyticsId `
  -resourceTags $resourceTags`