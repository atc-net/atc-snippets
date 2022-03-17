function Connect-IotHubWithDeviceProvisioningService {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $IotHubName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $DeviceProvisioningServiceName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ResourceGroupName,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 1000)]
    [int]
    $AllocationWeight = 1,

    [Parameter(Mandatory = $false)]
    [bool]
    $ApplyAllocationPolicy = $true
  )

  # import utility functions
  . "$PSScriptRoot\New-IotHubDeviceProvisioningServiceLink.ps1"
  . "$PSScriptRoot\Update-IotHubDeviceProvisioningServiceLink.ps1"

  Write-Host "Link iot hub '$IotHubName' with device provisioning service '$DeviceProvisioningServiceName'" -ForegroundColor DarkGreen

  Write-Host "  Querying for existing link between iot hub and device provisioning service" -ForegroundColor DarkYellow -NoNewline

  $linkJson = az iot dps linked-hub list `
    --dps-name $DeviceProvisioningServiceName `
    --resource-group $ResourceGroupName `
    --query "[?contains(name, '$IotHubName')]|[0].{allocationWeight: allocationWeight, applyAllocationPolicy: applyAllocationPolicy, hostName: name}"

    if ($null -eq $linkJson) {
      Write-Host " -> iot hub is not linked." -ForegroundColor Cyan

      New-IotHubDeviceProvisioningServiceLink `
        -DeviceProvisioningServiceName $DeviceProvisioningServiceName `
        -IotHubName $IotHubName `
        -ResourceGroupName $ResourceGroupName `
        -AllocationWeight $AllocationWeight `
        -ApplyAllocationPolicy $ApplyAllocationPolicy `
        -ResourceTags $ResourceTags
    }
    else {
      $linkResource = $linkJson | ConvertFrom-Json -AsHashtable

      if ($linkResource.allocationWeight -ne $AllocationWeight -or
          $linkResource.applyAllocationPolicy -ne $ApplyAllocationPolicy) {

        Write-Host " -> Iot hub link exists, but changes are detected" -ForegroundColor Cyan

        Update-IotHubDeviceProvisioningServiceLink `
          -IotHubHostName $linkResource.hostName `
          -DeviceProvisioningServiceName $DeviceProvisioningServiceName `
          -ResourceGroupName $ResourceGroupName `
          -AllocationWeight $AllocationWeight `
          -ApplyAllocationPolicy $ApplyAllocationPolicy
      }
      else {
        Write-Host " -> Iot hub link exists with desired configuration." -ForegroundColor Cyan
      }
    }
}