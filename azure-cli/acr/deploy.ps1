<#
  .SYNOPSIS
  Deploys Azure Container Registry instance

  .DESCRIPTION
  The deploy.ps1 script deploys an Azure Container Registry instance using Azure CLI to a resource group in the relevant environment.

  .PARAMETER resourceGroupName
  Specifies the name of the resource group

  .PARAMETER location
  Specifies the location where the services are deployed. Default is West Europe

  .PARAMETER registryName
  Specifies the name of the Container Registry

  .PARAMETER resourceTags
  Specifies the tag elements that will be used to tag the deployed services

  .INPUTS
  None. You cannot pipe objects to deploy.ps1.

  .OUTPUTS
  None. deploy.ps1 does not generate any output.

  .EXAMPLE
  PS> .\deploy.ps1 -resourceGroupName xxx-DEV-xxx -registryName xxxxxxdevxxxcr
#>
param (
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $resourceGroupName,

  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string]
  $location = "westeurope",

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $registryName,

  [Parameter(Mandatory = $false)]
  [string[]] $resourceTags = @()
)

#############################################################################################
# Azure Container Registry
#############################################################################################
Write-Host "Provision Azure Container Registry" -ForegroundColor DarkGreen

Write-Host "  Creating Azure Container Registry" -ForegroundColor DarkYellow
$containerRegistryLoginServer = az acr create `
  --resource-group $resourceGroupName `
  --location $location `
  --name $registryName `
  --sku Standard `
  --admin-enabled `
  --tags $resourceTags `
  --query loginServer `
  --output tsv

Throw-WhenError -output $containerRegistryLoginServer