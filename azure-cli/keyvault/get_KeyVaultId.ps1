function Get-KeyVaultId {
  param (
    [Parameter(Mandatory = $true)]
    [string]
    $name,

    [Parameter(Mandatory = $true)]
    [string]
    $resourceGroup
  )

  Write-Host "  Get key vault id" -ForegroundColor DarkYellow
  $kvId = az keyvault show `
    --name $name `
    --resource-group $resourceGroup `
    --query id

  Throw-WhenError -output $kvId

  return $kvId
}