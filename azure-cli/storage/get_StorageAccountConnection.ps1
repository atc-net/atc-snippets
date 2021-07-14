function Get-StorageAccountConnection {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $storageAccountName,

        [Parameter(Mandatory = $true)]
        [string]
        $resourceGroup
    )
    Write-Host "Get Storage Account connection string for $storageAccountName" -ForegroundColor DarkYellow
    $storageAccountConnection = az storage account show-connection-string `
        --name $storageAccountName `
        --resource-group $resourceGroupName `
        --output tsv

    return $storageAccountConnection

}