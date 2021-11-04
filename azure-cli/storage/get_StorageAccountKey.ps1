function Get-StorageAccountKey {
  param (
    [Parameter(Mandatory = $true)]
    [string]
    $storageAccountName,

    [Parameter(Mandatory = $true)]
    [string]
    $resourceGroupName
  )

  Write-Host "  Get storage account key" -ForegroundColor DarkYellow
  $key = az storage account keys list `
    -g $resourceGroupName `
    -n $storageAccountName `
    --query [0].value `
    --output tsv

  Throw-WhenError -output $key

  return $key
}