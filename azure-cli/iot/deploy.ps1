<#
  .SYNOPSIS
  Deploys Azure Container Registry instance

  .DESCRIPTION
  The deploy.ps1 script deploys an IoT Hub instance using Azure CLI to a resource group in the relevant environment.

  .PARAMETER location
  Specifies the location where the services are deployed. Default is West Europe

  .PARAMETER resourceGroupName
  Specifies the name of the resource group

  .PARAMETER iotHubName
  Specifies the name of the Container Registry

  .PARAMETER resourceTags
  Specifies the tag elements that will be used to tag the deployed services

  .INPUTS
  None. You cannot pipe objects to deploy.ps1.

  .OUTPUTS
  None. deploy.ps1 does not generate any output.

  .EXAMPLE
  PS> .\deploy.ps1 -resourceGroupName xxx-DEV-xxx -iotHubName xxxxxxdevxxiot
#>
param (
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
  $iotHubName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $iotHubSasPolicyNameWebApi,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $iotHubSasPolicyNameFunctionApp,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $iotHubProcessorConsumerGroupName,

  [Parameter(Mandatory = $false)]
  [string[]] $resourceTags = @()
)

#############################################################################################
# Provision IoTHub
#############################################################################################
Write-Host "Provision IoTHubs" -ForegroundColor DarkGreen

Write-Host "  Query for IoTHub $iotHubName" -ForegroundColor DarkYellow
$iotHubId = az iot hub show `
  --name $iotHubName `
  --resource-group $resourceGroupName `
  --query id `
  --output tsv

if (!$?) {
  Write-Host "  Creating IoTHub $iotHubName" -ForegroundColor DarkYellow
  $output = az iot hub create `
    --name $iotHubName `
    --resource-group $resourceGroupName `
    --location $location `
    --partition-count 4 `
    --retention-day 1 `
    --c2d-max-delivery-count 10 `
    --c2d-ttl 1 `
    --feedback-max-delivery-count 10 `
    --feedback-lock-duration 60 `
    --feedback-ttl 1 `
    --sku S2 `
    --unit 1

  Throw-WhenError -output $output

  $iotHubId = az iot hub show `
    --name $iotHubName `
    --query id `
    -o tsv

  Throw-WhenError -output $iotHubId

  Write-Host "  Adding tags to IoTHub $iotHubName" -ForegroundColor DarkYellow
  $output = az resource tag `
    --id $iotHubId `
    --tags $resourceTags

  Throw-WhenError -output $output

}
else {
  Write-Host "  IoTHub $iotHubName already exists, skipping creation" -ForegroundColor DarkYellow
}

Write-Host "  Creating consumer group $iotHubProcessorConsumerGroupName in IoT Hub $iotHubName" -ForegroundColor DarkYellow
$output = az iot hub consumer-group create `
  --n $iotHubProcessorConsumerGroupName `
  --hub-name $iotHubName

Throw-WhenError -output $output

Write-Host "  Query for IoTHub SasPolicy '$iotHubSasPolicyNameWebApi'" -ForegroundColor DarkYellow
$sasPolicyPrimaryApiKey = az iot hub policy show `
  --hub-name $iotHubName `
  --name $iotHubSasPolicyNameWebApi `
  --resource-group $resourceGroupName `
  --query primaryKey `
  --output tsv

if (!$?) {
  Write-Host "  Creating IoTHub SasPolicy '$iotHubSasPolicyNameWebApi'" -ForegroundColor DarkYellow
  $output = az iot hub policy create `
    --hub-name $iotHubName `
    --name $iotHubSasPolicyNameWebApi `
    --resource-group $resourceGroupName `
    --permissions ServiceConnect

  Throw-WhenError -output $output

}
else {
  Write-Host "  IoTHub SasPolicy '$iotHubSasPolicyNameWebApi' already exists, skipping creation" -ForegroundColor DarkYellow
}

Write-Host "  Query for IoTHub SasPolicy '$iotHubSasPolicyNameFunctionApp'" -ForegroundColor DarkYellow
$sasPolicyPrimaryFunctionKey = az iot hub policy show `
  --hub-name $iotHubName `
  --name $iotHubSasPolicyNameFunctionApp `
  --resource-group $resourceGroupName `
  --query primaryKey `
  --output tsv

if (!$?) {
  Write-Host "  Creating IoTHub SasPolicy '$iotHubSasPolicyNameFunctionApp'" -ForegroundColor DarkYellow
  $output = az iot hub policy create `
    --hub-name $iotHubName `
    --name $iotHubSasPolicyNameFunctionApp `
    --resource-group $resourceGroupName `
    --permissions ServiceConnect

  Throw-WhenError -output $output

  $sasPolicyPrimaryFunctionKey = az iot hub policy show `
    --hub-name $iotHubName `
    --name $iotHubSasPolicyNameFunctionApp `
    --resource-group $resourceGroupName `
    --query primaryKey `
    --output tsv
}
else {
  Write-Host "  IoTHub SasPolicy '$iotHubSasPolicyNameFunctionApp' already exists, skipping creation" -ForegroundColor DarkYellow
}