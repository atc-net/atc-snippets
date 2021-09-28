function New-Subnet {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $vnetname,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $subnetname,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $resourceGroupName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $addressPrefix
    )

    $output = az network vnet subnet list `
        --vnet-name $vnetname `
        --resource-group $resourceGroupName `
        --query "[?name=='$subnetname']"

    if ($output -eq "[]") {
        #  Subnet not created, lets create it
        Write-Host "  Creating subnet" -ForegroundColor DarkYellow
        $output = az network vnet subnet create `
            --address-prefixes $addressPrefix `
            --name $subnetname `
            --resource-group $resourceGroupName `
            --vnet-name $vnetname

        Throw-WhenError -output $output

    } else {
        #   Subnet already exist, lets check if namespace is correct
        $outputJson = $output | ConvertFrom-Json
        if ($outputJson.addressPrefix -ne $addressPrefix) {
            Write-Host " Subnet already created, but with wrong subnet prefix. Please remote subnet with name $subnetname and run again." -ForegroundColor Red
            Exit 1
        }
    }
}