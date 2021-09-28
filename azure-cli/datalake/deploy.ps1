<#
  .SYNOPSIS
  Deploys Azure Data Lake

  .DESCRIPTION
  The deploy.ps1 script deploys an Azure Data Lake using Azure CLI to a resource group in the relevant environment.

  .PARAMETER environmentType
  Specifies the environment type. Staging (DevTest) or Production

  .PARAMETER location
  Specifies the location where the services are deployed. Default is West Europe

  .PARAMETER resourceGroupName
  Specifies the name of the resource group

  .PARAMETER dataLakeName
  Specifies the name of the data lake

  .PARAMETER resourceTags
  Specifies the tag elements that will be used to tag the deployed services

  .INPUTS
  None. You cannot pipe objects to deploy.ps1.

  .OUTPUTS
  None. deploy.ps1 does not generate any output.

  .EXAMPLE
  PS> .\deploy.ps1 -environmentType DevTest -environmentName Dev -resourceGroupName xxx-DEV-xxx -dataLakeName xxxxxxdevxxxdls
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
  $dataLakeName,

  [Parameter(Mandatory = $false)]
  [string[]] $resourceTags = @()
)

#############################################################################################
# Resource naming section
#############################################################################################

$dataLakeFilesystems = @(
  "landingzone",
  "intermediate",
  "delivery"
)

#############################################################################################
# Azure Data Lake
#############################################################################################
Write-Host "Provision Azure Data Lake" -ForegroundColor DarkGreen

Write-Host "  Creating Azure Data Lake" -ForegroundColor DarkYellow

$datalake = az storage account create --name $dataLakeName `
  --resource-group $resourceGroupName `
  --location $location --sku Standard_LRS `
  --kind StorageV2 --hns true `
  --output tsv

Throw-WhenError -output $datalake

foreach ($fs in $dataLakeFilesystems) {
    $exists = az storage fs exists -n $fs --account-name $dataLakeName --query exists
    if ($exists -eq "true") {
      Write-Host "Filesystem: $fs already exist, will not recreate..."
    } else {
      az storage fs create -n $fs --account-name $dataLakeName
    }
}