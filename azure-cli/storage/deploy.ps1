param (
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $resourceGroupName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $storageAccountName,

  [Parameter(Mandatory = $false)]
  [string]
  $location = "westeurope",

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