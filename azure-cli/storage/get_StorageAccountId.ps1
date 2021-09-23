function Get-StorageAccountId {
    param (
      [Parameter(Mandatory=$true)]
      [string]
      $storageAccountName,

      [Parameter(Mandatory=$true)]
      [string]
      $resourceGroupName
    )

    Write-Host "  Get storage account id" -ForegroundColor DarkYellow
    $storageAccountId = az storage account show `
      --name $storageAccountName `
      --resource-group $resourceGroupName `
      --query id

    Throw-WhenError -output $storageAccountId

    return $storageAccountId
}