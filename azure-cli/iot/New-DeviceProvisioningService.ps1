using module "./DeviceProvisioningServiceAllocationPolicyNames.psm1"

function New-DeviceProvisioningService {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [Alias("Name")]
    [string]
    $DeviceProvisioningServiceName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ResourceGroupName,

    [Parameter(Mandatory = $false)]
    [string]
    $Sku = "S1",

    [Parameter(Mandatory = $false)]
    [int]
    $NumberOfUnits = 1,

    [Parameter(Mandatory = $false)]
    [ValidateSet([DeviceProvisioningServiceAllocationPolicyNames])]
    [string]
    $AllocationPolicy = "Hashed",

    [Parameter(Mandatory = $false)]
    [string]
    $Location = "westeurope",

    [Parameter(Mandatory = $false)]
    [string[]]
    $ResourceTags = @()
  )

  Write-Host "  Creating device provisioning service '$DeviceProvisioningServiceName'" -ForegroundColor DarkYellow

  $output = az iot dps create `
  --name $DeviceProvisioningServiceName `
  --location $Location `
  --resource-group $resourceGroupName `
  --sku $Sku `
  --unit $NumberOfUnits `
  --tags $ResourceTags

  Throw-WhenError -output $output

  Write-Host "  Setting desired allocationPolicy '$AllocationPolicy' on the device provisioning service '$DeviceProvisioningServiceName'" -ForegroundColor DarkYellow
  $output = az iot dps update `
    --name $DeviceProvisioningServiceName `
    --resource-group $ResourceGroupName `
    --set properties.allocationPolicy=$AllocationPolicy

  Throw-WhenError -output $output
}