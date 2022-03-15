param (
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $resourceGroupName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $dataLakeName,

  [Parameter(Mandatory = $false)]
  [string]
  $location = "westeurope",

  [Parameter(Mandatory = $false)]
  [string[]]
  $resourceTags = @()
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

$datalake = az storage account create `
  --name $dataLakeName `
  --resource-group $resourceGroupName `
  --location $location `
  --sku Standard_LRS `
  --kind StorageV2 `
  --hns true `
  --output tsv

Throw-WhenError -output $datalake

foreach ($fs in $dataLakeFilesystems) {
  $exists = az storage fs exists -n $fs --account-name $dataLakeName --query exists
  if ($exists -eq "true") {
    Write-Host "Filesystem: $fs already exist, will not recreate..."
  }
  else {
    az storage fs create -n $fs --account-name $dataLakeName
  }
}