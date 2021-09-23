function Get-CosmosConnectionString {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $resourceGroupName,
        [Parameter(Mandatory = $true)]
        [string]
        $cosmosAccountName
    )

    Write-Host "  Getting Cosmos account key" -ForegroundColor DarkYellow
    $cosmosKey = az cosmosdb keys list `
        --name $cosmosAccountName `
        --resource-group $resourceGroupName `
        --query primaryMasterKey

    Throw-WhenError -output $cosmosKey

    return "AccountEndpoint=https://" + $cosmosAccountName + ".documents.azure.com:443/;AccountKey=" + $cosmosKey + ";"
}