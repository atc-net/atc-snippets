param (
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $resourceGroupName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $timeseriesinsightsName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $storageAccountName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $eventHubNamespaceName,

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
. "$PSScriptRoot\..\storage\get_StorageAccountKey.ps1"

#############################################################################################
# Resource naming section
#############################################################################################
$storageAccountKey = Get-StorageAccountKey  $storageAccountName $resourceGroupName
$eventHubName = "xxxEvents"

#############################################################################################
# TimeSeriesInsights (TSI)
#############################################################################################
Write-Host "Provision TimeSeriesInsights" -ForegroundColor DarkGreen

Write-Host "  Provision TimeSeriesInsights Environment" -ForegroundColor DarkYellow
$output = az tsi environment gen2 create `
  --environment-name $timeseriesinsightsName `
  --resource-group $resourceGroupName `
  --location $location `
  --sku name="L1" capacity=1 `
  --time-series-id-properties name="`$dtId" type=String `
  --warm-store-configuration data-retention=P7D `
  --storage-configuration account-name=$storageAccountName management-key=$storageAccountKey `
  --tags $resourceTags

Throw-WhenError -output $output

Write-Host "  Query eventhub resource id for $($eventHubName)" -ForegroundColor DarkYellow
$eventHubResourceId = az eventhubs eventhub show `
  --namespace-name $eventHubNamespaceName `
  -n $eventHubName `
  --resource-group $resourceGroupName `
  --query id `
  -o tsv

Throw-WhenError -output $eventHubResourceId

Write-Host "  Get primary key for $($eventHubName)" -ForegroundColor DarkYellow
$eventHubPrimaryKey = az eventhubs eventhub authorization-rule keys list `
  --eventhub-name $eventHubName `
  --resource-group $resourceGroupName `
  --namespace-name $eventHubNamespaceName `
  --name "SendListen" `
  --query primaryKey `
  -o tsv

Throw-WhenError -output $eventHubPrimaryKey

Write-Host "  Provision TimeSeriesInsights Event-Source" -ForegroundColor DarkYellow
$output = az tsi event-source eventhub create `
  --consumer-group-name "TsiIngestion" `
  --environment-name $timeseriesinsightsName `
  --event-hub-name $eventHubName `
  --event-source-name $eventHubName `
  --event-source-resource-id $eventHubResourceId `
  --shared-access-policy-name "SendListen" `
  --namespace $eventHubNamespaceName `
  --location $location `
  --resource-group $resourceGroupName `
  --shared-access-key $eventHubPrimaryKey `
  --tags $resourceTags

Throw-WhenError -output $output