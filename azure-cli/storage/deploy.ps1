<#
  .SYNOPSIS
  Deploys Azure Storage Account

  .DESCRIPTION
  The deploy.ps1 script deploys an Azure Storage Account using the CLI tool to a resource group in the relevant environment.

  .PARAMETER environmentType
  Specifies the environment type. Staging (DevTest) or production

  .PARAMETER location
  Specifies the location where the services are deployed. Default is West Europe

  .PARAMETER resourceGroupName
  Specifies the name of the resource group

  .PARAMETER storageAccountName
  Specifies the name of the Storage Account

  .PARAMETER resourceTags
  Specifies the tag elements that will be used to tag the deployed services

  .INPUTS
  None. You cannot pipe objects to deploy.ps1.

  .OUTPUTS
  None. deploy.ps1 does not generate any output.

  .EXAMPLE
  PS> .\deploy.ps1 -environmentType DevTest -environmentName Dev -resourceGroupName xxx-DEV-xxx -registryName xxxxxxdevxxxcr
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
  $storageAccountName,

  [Parameter(Mandatory = $false)]
  [string[]] $resourceTags = @()
)

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
