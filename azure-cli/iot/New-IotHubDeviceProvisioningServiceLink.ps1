function New-IotHubDeviceProvisioningServiceLink {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $DeviceProvisioningServiceName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $IotHubName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ResourceGroupName,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1,1000)]
    [int]
    $AllocationWeight = 1,

    [Parameter(Mandatory = $false)]
    [bool]
    $ApplyAllocationPolicy = $true,

    [Parameter(Mandatory = $false)]
    [string[]]
    $ResourceTags = @()
  )

  Write-Host "  Creating link between iot hub '$IotHubName' and device provisioning service '$DeviceProvisioningServiceName'" -ForegroundColor DarkYellow

  $output = az iot dps linked-hub create `
    --dps-name $DeviceProvisioningServiceName `
    --resource-group $ResourceGroupName `
    --hub-name $IotHubName `
    --hub-resource-group $ResourceGroupName `
    --allocation-weight $AllocationWeight `
    --apply-allocation-policy $ApplyAllocationPolicy

  Throw-WhenError -output $output
}