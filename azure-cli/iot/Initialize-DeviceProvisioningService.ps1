using module "./DeviceProvisioningServiceAllocationPolicyNames.psm1"

function Initialize-DeviceProvisioningService {
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

  # import utility functions
  . "$PSScriptRoot\New-DeviceProvisioningService.ps1"
  . "$PSScriptRoot\Update-DeviceProvisioningService.ps1"

  Write-Host "Provision device provisioning service '$DeviceProvisioningServiceName'" -ForegroundColor DarkGreen

  Write-Host "  Querying for existing device provisioning service" -ForegroundColor DarkYellow -NoNewline

  $dpsJson = az iot dps list `
    --resource-group $ResourceGroupName `
    --query "[?name=='$DeviceProvisioningServiceName']|[0].{allocationPolicy: properties.allocationPolicy, numberOfUnits: sku.capacity}"

  if ($null -eq $dpsJson) {
    Write-Host " -> Resource not found." -ForegroundColor Cyan

    New-DeviceProvisioningService `
      -Name $DeviceProvisioningServiceName `
      -ResourceGroupName $ResourceGroupName `
      -Sku $Sku `
      -NumberOfUnits $NumberOfUnits `
      -AllocationPolicy $AllocationPolicy `
      -Location $Location `
      -ResourceTags $ResourceTags
  }
  else {
    $dpsResource = $dpsJson | ConvertFrom-Json -AsHashtable

    if ($dpsResource.allocationPolicy -ne $AllocationPolicy -or
        $dpsResource.numberOfUnits -ne $NumberOfUnits) {
      Write-Host " -> Resource exists, but changes are detected" -ForegroundColor Cyan

      Update-DeviceProvisioningService `
        -Name $DeviceProvisioningServiceName `
        -ResourceGroupName $ResourceGroupName `
        -NumberOfUnits $NumberOfUnits `
        -AllocationPolicy $AllocationPolicy
    }
    else {
      Write-Host " -> Resource exists with desired configuration." -ForegroundColor Cyan
    }
  }
}