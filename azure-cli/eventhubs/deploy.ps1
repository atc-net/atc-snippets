param (
  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [ValidateSet('DevTest', 'Production')]
  [string]
  $environmentType = "DevTest",

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $environmentName
)

#############################################################################################
# Configure names and options
#############################################################################################
Write-Host "Initialize deployment" -ForegroundColor DarkGreen

# import utility functions
. ".\deploy.utilities.ps1"
. ".\deploy.naming.ps1"

# Install required extensions
Write-Host "  Installing required extensions" -ForegroundColor DarkYellow
$output = az extension add `
  --name application-insights `
  --yes

Throw-WhenError -output $output

$output = az extension add `
  --name storage-preview `
  --yes

Throw-WhenError -output $output

# Naming rule configurations
$companyAbbreviation = "xxx"
$systemName          = "xxx"
$systemAbbreviation  = "xxx"
$serviceName         = "xxx"
$serviceAbbreviation = "xxx"

# Location
$location = "westeurope"

# Resource tags
$resourceTags = @(
  "Owner=Auto Deployed",
  "System=$systemName",
  "Environment=$environmentName",
  "Service=$serviceName",
  "Source=https://repo_url"
)

#############################################################################################
# Resource naming section
#############################################################################################

# Environment Resource Names
$envResourceGroupName   = Get-ResourceGroupName -systemName $systemName -environmentName $environmentName
$envResourceName        = Get-ResourceName -companyAbbreviation $companyAbbreviation -systemAbbreviation $systemAbbreviation -environmentName $environmentName

# Resource Names
$resourceGroupName      = Get-ResourceGroupName -serviceName $serviceName -systemName $systemName -environmentName $environmentName
$resourceName           = Get-ResourceName -serviceAbbreviation $serviceAbbreviation -companyAbbreviation $companyAbbreviation -systemAbbreviation $systemAbbreviation -environmentName $environmentName

$storageAccountName     = $resourceName
$eventHubNamespaceName  = $resourceName
$eventHubNames = @(
  "xxxEvents",
  "yyyEvents"
)
$eventHubListeners = @(
  "Ingestion"
)

# Max 50 characters for Name - since consumergroup names can only be of this size!
$eventHubConsumerGroups = @(
  @{ EventHub = 'xxxEvents';          Name = 'Ingestion' },
  @{ EventHub = 'yyyEvents';          Name = 'Ingestion' }
)

$dataCaptureContainer = 'landingzone'

# Write setup

Write-Host "**********************************************************************" -ForegroundColor White
Write-Host "* Environment name                 : $environmentName" -ForegroundColor White
Write-Host "* Env. resource group name         : $envResourceGroupName" -ForegroundColor White
Write-Host "* Resource group name              : $resourceGroupName" -ForegroundColor White
Write-Host "* Storage Account name                  : $storageAccountName" -ForegroundColor White
for ($i = 0; $i -lt $eventHubNames.Count; $i++) {
  Write-Host "* EventHub name $($i+1)                       : $($eventHubNames[$i])" -ForegroundColor White
}
for ($i = 0; $i -lt $eventHubListeners.Count; $i++) {
  Write-Host "* EventHub listener $($i+1)                   : $($eventHubListeners[$i])" -ForegroundColor White
}
$i = 1
foreach ($eventHubConsumerGroup in $eventHubConsumerGroups) {
  Write-Host "* EventHub consumer group $i             : $($eventHubConsumerGroup.Name)" -ForegroundColor White
  $i++
}
Write-Host "**********************************************************************" -ForegroundColor White

#############################################################################################
# Provision resource group
#############################################################################################
Write-Host "Provision resource group" -ForegroundColor DarkGreen

Write-Host "  Creating resource group" -ForegroundColor DarkYellow
$output = az group create `
  --name $resourceGroupName `
  --location $location `
  --tags $resourceTags

Throw-WhenError -output $output

#############################################################################################
# Provision storage account
#############################################################################################
Write-Host "Provision storage account" -ForegroundColor DarkGreen

Write-Host "  Creating storage account" -ForegroundColor DarkYellow
$storageAccountId = az storage account create `
  --name $storageAccountName `
  --location $location `
  --resource-group $resourceGroupName `
  --encryption-service 'blob' `
  --encryption-service 'file' `
  --sku 'Standard_LRS' `
  --https-only 'true' `
  --kind 'StorageV2' `
  --tags $resourceTags `
  --query id

Throw-WhenError -output $storageAccountId

#############################################################################################
# Provision Event Hub namespace
#############################################################################################
Write-Host "Provision event hub namespace" -ForegroundColor DarkGreen

Write-Host "  Creating event hub namespace" -ForegroundColor DarkYellow
$output = az eventhubs namespace create `
  --name $eventHubNamespaceName `
  --resource-group $resourceGroupName `
  --sku 'Standard' `
  --tags $resourceTags

Throw-WhenError -output $output

foreach ($eventHubListener in $eventHubListeners) {
  Write-Host "  Creating listener authorization rule $eventHubListener" -ForegroundColor DarkYellow
  $output = az eventhubs namespace authorization-rule create `
    --name $eventHubListener `
    --resource-group $resourceGroupName `
    --namespace-name $eventHubNamespaceName `
    --rights Listen

  Throw-WhenError -output $output
}

Write-Host "  Creating sender authorization rule" -ForegroundColor DarkYellow
$output = az eventhubs namespace authorization-rule create `
  --name sender `
  --resource-group $resourceGroupName `
  --namespace-name $eventHubNamespaceName `
  --rights Send

Throw-WhenError -output $output

#############################################################################################
# Provision Event Hubs
#############################################################################################
Write-Host "Provision event hubs" -ForegroundColor DarkGreen

foreach ($eventHubName in $eventHubNames) {
  Write-Host "  Creating event hub - $eventHubName" -ForegroundColor DarkYellow
  $output = az eventhubs eventhub create `
    --name $eventHubName `
    --namespace-name $eventHubNamespaceName `
    --resource-group $resourceGroupName `
    --message-retention 7 `
    --partition-count 4 `
    --enable-capture true `
    --capture-interval 300 `
    --capture-size-limit 314572800 `
    --destination-name 'EventHubArchive.AzureBlockBlob' `
    --storage-account $storageAccountId `
    --blob-container $dataCaptureContainer `
    --archive-name-format "$dataFolder/{Namespace}/{EventHub}/y={Year}/m={Month}/d={Day}/h={Hour}/{Year}_{Month}_{Day}_{Hour}_{Minute}_{Second}_{PartitionId}" `
    --skip-empty-archives true

  Throw-WhenError -output $output
}

Write-Host "  Creating consumer groups for eventhubs in namespace $eventHubNamespaceName" -ForegroundColor DarkYellow
foreach ($eventHubConsumerGroup in $eventHubConsumerGroups) {
    $consumerGroupName = $eventHubConsumerGroup.Name
    $eventHubName = $eventHubConsumerGroup.EventHub

    Write-Host "  Create consumer-group $consumerGroupName on eventhub $eventHubName" -ForegroundColor DarkYellow
    $output = az eventhubs eventhub consumer-group create `
      --eventhub-name $eventHubName `
      --resource-group $resourceGroupName `
      --namespace-name $eventHubNamespaceName `
      --name $consumerGroupName

    Throw-WhenError -output $output
}