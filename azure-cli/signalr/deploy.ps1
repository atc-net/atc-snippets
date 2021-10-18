<#
  .SYNOPSIS
  Deploys SignalR instance

  .DESCRIPTION
  The deploy.ps1 script deploys an Azure SignalR instance using Azure CLI to a resource group in the relevant environment.

  .PARAMETER location
  Specifies the location where the services are deployed. Default is West Europe

  .PARAMETER resourceGroupName
  Specifies the name of the resource group

  .PARAMETER signalRName
  Specifies the name of the SignalR

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
  [string]
  $location = "westeurope",

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $resourceGroupName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $signalRName,

  [Parameter(Mandatory = $true)]
  [ValidateSet('Default', 'Serverless', 'Classic')]
  [string]
  $serviceMode = "Default",

  [Parameter(Mandatory = $false)]
  [string[]] $resourceTags = @()
)

#############################################################################################
# Provision SignalR
#############################################################################################
Write-Host "Provision SignalR" -ForegroundColor DarkGreen

Write-Host "  Creating SignalR" -ForegroundColor DarkYellow
$output = az signalr create `
  --name $signalRName `
  --location $location `
  --resource-group $resourceGroupName `
  --sku Standard_S1 `
  --unit-count 1 `
  --allowed-origins * `
  --service-mode $serviceMode

Throw-WhenError -output $output