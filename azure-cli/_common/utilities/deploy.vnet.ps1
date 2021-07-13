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