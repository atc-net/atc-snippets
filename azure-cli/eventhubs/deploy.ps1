<#
  .SYNOPSIS
  Deploys Event Hub namespace and Event Hub

  .DESCRIPTION
  The deploy.ps1 script deploys an Event Hub namespace and Event Hub using Azure CLI to a resource group in the relevant environment.

  .PARAMETER environmentType
  Specifies the environment type. Staging (DevTest) or Production

  .PARAMETER location
  Specifies the location where the services are deployed. Default is West Europe

  .PARAMETER resourceGroupName
  Specifies the name of the resource group

  .PARAMETER eventHubNamespaceName
  Specifies the name of the event hub namespace

  .PARAMETER storageAccountName
  Specifies the name of the storage account

  .PARAMETER resourceTags
  Specifies the tag elements that will be used to tag the deployed services

  .INPUTS
  None. You cannot pipe objects to deploy.ps1.

  .OUTPUTS
  None. deploy.ps1 does not generate any output.

  .EXAMPLE
  PS> .\deploy.ps1 -environmentType DevTest -environmentName Dev -resourceGroupName xxx-DEV-xxx -eventHubNamespaceName xxxxxxdevxxxevhns
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
  $eventHubNamespaceName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $storageAccountName,

  [Parameter(Mandatory = $false)]
  [string[]] $resourceTags = @()
)

#############################################################################################
# Configure names and options
#############################################################################################

# import utility functions
. "$PSScriptRoot\..\storage\get_StorageAccountId.ps1"

#############################################################################################
# Resource naming section
#############################################################################################

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

#############################################################################################
# Provision Event Hub namespace
#############################################################################################
Write-Host "Provision event hub namespace" -ForegroundColor DarkGreen

Write-Host "  Creating event hub namespace $eventHubNamespaceName" -ForegroundColor DarkYellow
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
  --name Sender `
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
    --storage-account (Get-StorageAccountId -storageAccountName $storageAccountName -resourceGroup $resourceGroupName) `
    --blob-container $dataCaptureContainer `
    --archive-name-format "$dataFolder/{Namespace}/{EventHub}/y={Year}/m={Month}/d={Day}/h={Hour}/{Year}_{Month}_{Day}_{Hour}_{Minute}_{Second}_{PartitionId}" `
    --skip-empty-archives true

  Throw-WhenError -output $output

  Write-Host "  Creating sender & listen authorization rule for event hub $($eventHubName)" -ForegroundColor DarkYellow
  $output = az eventhubs eventhub authorization-rule create `
    --name SendListen `
    --eventhub-name $eventHubName `
    --resource-group $resourceGroupName `
    --namespace-name $eventHubNamespaceName `
    --rights Send Listen

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