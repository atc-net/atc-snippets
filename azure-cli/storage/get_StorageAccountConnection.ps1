function Get-StorageConnectionString {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $storageAccountName,

        [Parameter(Mandatory = $true)]
        [string]
        $resourceGroup
    )

    Write-Host "  Get Storage Account connection string for $storageAccountName" -ForegroundColor DarkYellow
    $storageAccountConnectionString = az storage account show-connection-string `
        --name $storageAccountName `
        --resource-group $resourceGroupName `
        --query connectionString `
        --output tsv

    Throw-WhenError -output $storageAccountConnectionString

    return $storageAccountConnectionString
}