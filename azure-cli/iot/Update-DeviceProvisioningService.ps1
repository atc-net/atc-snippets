function Update-DeviceProvisioningService {
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
    [int]
    $NumberOfUnits = 1,

    [Parameter(Mandatory = $false)]
    [ValidateSet([DeviceProvisioningServiceAllocationPolicyNames])]
    [string]
    $AllocationPolicy = "Hashed"
  )

  Write-Host "  Updating device provisioning service '$DeviceProvisioningServiceName'" -ForegroundColor DarkYellow
  $output = az iot dps update `
    --name $DeviceProvisioningServiceName `
    --resource-group $ResourceGroupName `
    --set properties.allocationPolicy=$AllocationPolicy `
    --set sku.capacity=$NumberOfUnits

  Throw-WhenError -output $output
}