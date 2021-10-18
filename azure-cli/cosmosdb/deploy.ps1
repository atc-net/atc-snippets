<#
  .SYNOPSIS
  Deploys Azure Cosmos database

  .DESCRIPTION
  The deploy.ps1 script deploys an Azure Cosmos database account using Azure CLI to a resource group in the relevant environment.

  .PARAMETER location
  Specifies the location where the services are deployed. Default is West Europe

  .PARAMETER resourceGroupName
  Specifies the name of the resource group

  .PARAMETER cosmosAccountName
  Specifies the name of the Cosmos database

  .PARAMETER resourceTags
  Specifies the tag elements that will be used to tag the deployed services

  .INPUTS
  None. You cannot pipe objects to deploy.ps1.

  .OUTPUTS
  None. deploy.ps1 does not generate any output.

  .EXAMPLE
  PS> .\deploy.ps1 -resourceGroupName xxx-DEV-xxx -cosmosAccountName xxxxxxdevxxxcosmos
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
  $cosmosAccountName,

  [Parameter(Mandatory = $false)]
  [string[]] $resourceTags = @()
)

#############################################################################################
# Provision Cosmos Db account
#############################################################################################
Write-Host "Provision Cosmos db account" -ForegroundColor DarkGreen

Write-Host "  Creating Cosmos db account" -ForegroundColor DarkYellow
az cosmosdb create `
  -n $cosmosAccountName `
  -g $resourceGroupName `
  --default-consistency-level Strong `
  --locations regionName=$location failoverPriority=0 isZoneRedundant=False