function New-Vnet {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $name,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ResourceGroup,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $addressprefix,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [array]
        $resourceTags
    )

    $output = az network vnet list `
        --resource-group $ResourceGroup `
        --query "[?name=='$name']"

    if ($output -eq "[]") {
        #  Subnet not created, lets create it
        Write-Host "  Creating vnet" -ForegroundColor DarkYellow
        $output = az network vnet create `
            --name $name `
            --resource-group $ResourceGroup `
            --address-prefix $addressprefix `
            --location $location `
            --tags $resourceTags

        Throw-WhenError -output $output

    } else {
        #   Vnet already exist, lets check if namespace is correct addressspace
        $outputJson = $output | ConvertFrom-Json
        $addressspace = $outputJson.addressSpace
        $addressspaceCreated = $false

        foreach ($space in $addressspace) {
            if ($space.addressPrefixes -eq $addressprefix) {
                #   Address space found, we are just fine
                $addressspaceCreated = $true
            }
        }

        if ($addressspaceCreated -eq $false) {
            Write-Host "   VNET was created, but it does not have the right addressspace associated. Lets update the VNET with it" -ForegroundColor DarkYellow
            $output =  az network vnet update `
                --name $name `
                --resource-group $ResourceGroup `
                --address-prefixes $addressprefix

            Throw-WhenError -output $output
        }
    }
}