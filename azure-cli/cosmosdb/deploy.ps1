param (
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $resourceGroupName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $cosmosAccountName,

  [Parameter(Mandatory = $false)]
  [string]
  $location = "westeurope",

  [Parameter(Mandatory = $false)]
  [string[]]
  $resourceTags = @()
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