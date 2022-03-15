param (
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $resourceGroupName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $registryName,

  [Parameter(Mandatory = $false)]
  [string]
  $location = "westeurope",

  [Parameter(Mandatory = $false)]
  [string[]]
  $resourceTags = @()
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