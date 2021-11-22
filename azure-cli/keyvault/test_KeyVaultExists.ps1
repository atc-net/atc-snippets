function Test-KeyVaultExists {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $keyVaultName,

        [Parameter(Mandatory = $true)]
        [string]
        $resourceGroupName
    )

    Write-Host "  Checking for existing '$keyVaultName' Key Vault" -ForegroundColor DarkYellow
    $output = az keyvault list `
        --resource-group $resourceGroupName `
        --resource-type vault --query "contains([].name, '$keyVaultName')"

    Throw-WhenError -output $output

    Write-Host "    Key Vault already exists: $output"

    return [System.Convert]::ToBoolean($output)
}