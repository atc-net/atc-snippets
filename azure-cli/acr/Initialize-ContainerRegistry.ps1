using module "./ContainerRegistrySkuNames.psm1"

function Initialize-ContainerRegistry {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [Alias("Name")]
    [string]
    $ContainerRegistryName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ResourceGroupName,

    [Parameter(Mandatory = $false)]
    [ValidateSet([ContainerRegistrySkuNames])]
    [string]
    $Sku = "Standard",

    [Parameter(Mandatory = $false)]
    [bool]
    $AdminEnabled = $true,

    [Parameter(Mandatory = $false)]
    [string]
    $Location = "westeurope",

    [Parameter(Mandatory = $false)]
    [string[]]
    $ResourceTags = @()
  )

  # import utility functions
  . "$PSScriptRoot\New-ContainerRegistry.ps1"
  . "$PSScriptRoot\Update-ContainerRegistry.ps1"

  Write-Host "Provision container registry '$ContainerRegistryName'" -ForegroundColor DarkGreen

  Write-Host "  Querying for existing container registry" -ForegroundColor DarkYellow -NoNewline

  $acrJson = az acr list `
    --resource-group $ResourceGroupName `
    --query "[?name=='$ContainerRegistryName']|[0].{adminUserEnabled: adminUserEnabled, sku: sku.tier}"

  if ($null -eq $acrJson) {
    Write-Host " -> Resource not found." -ForegroundColor Cyan

    New-ContainerRegistry `
      -Name $ContainerRegistryName `
      -ResourceGroupName $ResourceGroupName `
      -Sku $Sku `
      -AdminEnabled $AdminEnabled `
      -Location $Location `
      -ResourceTags $ResourceTags
  }
  else {
    $acrResource = $acrJson | ConvertFrom-Json -AsHashtable

    if ($acrResource.sku -ne $Sku -or
        $acrResource.adminUserEnabled -ne $AdminEnabled) {

      Write-Host " -> Resource exists, but changes are detected" -ForegroundColor Cyan

      Update-ContainerRegistry `
        -Name $ContainerRegistryName `
        -ResourceGroupName $ResourceGroupName `
        -Sku $Sku `
        -AdminEnabled $AdminEnabled
    }
    else {
      Write-Host " -> Resource exists with desired configuration." -ForegroundColor Cyan
    }
  }
}