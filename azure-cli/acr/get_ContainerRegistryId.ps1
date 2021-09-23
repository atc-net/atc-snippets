function Get-ContainerRegistryId {
  param (
    [Parameter(Mandatory=$true)]
    [string]
    $registryName,

    [Parameter(Mandatory=$true)]
    [string]
    $resourceGroupName
  )

  Write-Host "  Get container registry id" -ForegroundColor DarkYellow
  $registryId = az acr show `
    --name $registryName `
    --resource-group $resourceGroupName `
    --query id

  Throw-WhenError -output $registryId

  return $registryId
}