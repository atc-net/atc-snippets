function Update-IotHubDeviceProvisioningServiceLink {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $DeviceProvisioningServiceName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $IotHubHostName,

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
    $ApplyAllocationPolicy = $true
  )

  Write-Host "  Updating link between iot hub '$IotHubName' and device provisioning service '$DeviceProvisioningServiceName'" -ForegroundColor DarkYellow

  $output = az iot dps linked-hub update `
    --dps-name $DeviceProvisioningServiceName `
    --linked-hub $IotHubHostName `
    --resource-group $ResourceGroupName `
    --allocation-weight $AllocationWeight `
    --apply-allocation-policy $ApplyAllocationPolicy

  Throw-WhenError -output $output
}