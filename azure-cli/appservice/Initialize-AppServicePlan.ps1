using module "./AppServicePlanSkuNames.psm1"

function Initialize-AppServicePlan {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [Alias("Name")]
    [string]
    $AppServicePlanName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet([AppServicePlanSkuNames])]
    [string]
    $Sku,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ResourceGroupName,

    [Parameter(Mandatory = $false)]
    [bool]
    $UseLinux = $false,

    [Parameter(Mandatory = $false)]
    [string]
    $Location = "westeurope",

    [Parameter(Mandatory = $false)]
    [string[]]
    $ResourceTags = @()
  )

  # import utility functions
  . "$PSScriptRoot\..\utilities\ConvertFrom-LocationDisplayName.ps1"
  . "$PSScriptRoot\New-AppServicePlan.ps1"
  . "$PSScriptRoot\Update-AppServicePlan.ps1"

  Write-Host "Provision app service plan '$AppServicePlanName'" -ForegroundColor DarkGreen

  Write-Host "  Querying for existing app service plan" -ForegroundColor DarkYellow -NoNewline

  $appServicePlanJson = az appservice plan list `
    --resource-group $ResourceGroupName `
    --query "[?name=='$($AppServicePlanName)'] | [0].{id: id, sku: sku.size, location: location, os: kind}"

  if ($null -eq $appServicePlanJson) {
    Write-Host " -> Resource not found." -ForegroundColor Cyan

    $appServicePlanId = New-AppServicePlan `
      -Name $AppServicePlanName `
      -Sku $Sku `
      -UseLinux $UseLinux `
      -ResourceGroupName $ResourceGroupName `
      -Location $Location `
      -ResourceTags $ResourceTags
  }
  else {
    $appServicePlanResource = $appServicePlanJson | ConvertFrom-Json -AsHashtable

    if ($true -eq $UseLinux -and $appServicePlanResource.os -ne "linux") {
      throw "App Service Plan '$AppServicePlanName' is already Windows and cannot be converted in-place to Linux"
    }
    elseif ($false -eq $UseLinux -and $appServicePlanResource.os -eq "linux") {
      throw "App Service Plan '$AppServicePlanName' is already Linux and cannot be converted in-place to Windows"
    }

    if ($appServicePlanResource.sku -ne $Sku -or 
       ($appServicePlanResource.location | ConvertFrom-LocationDisplayName) -ne $Location) {
      Write-Host " -> Resource exists, but changes are detected" -ForegroundColor Cyan

      $appServicePlanId = Update-AppServicePlan `
        -AppServicePlanName $AppServicePlanName `
        -ResourceGroupName $ResourceGroupName `
        -Sku $Sku `
        -Location $Location
    }
    else {
      Write-Host " -> Resource exists with desired configuration." -ForegroundColor Cyan

      $appServicePlanId = $appServicePlanResource.id
    }
  }

  return $appServicePlanId
}