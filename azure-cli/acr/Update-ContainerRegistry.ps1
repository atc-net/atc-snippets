using module "./ContainerRegistrySkuNames.psm1"

function Update-ContainerRegistry {
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
    $AdminEnabled = $true
  )

  Write-Host "  Updating container registry '$ContainerRegistryName'" -ForegroundColor DarkYellow
  $output = az acr update `
    --name $ContainerRegistryName `
    --resource-group $ResourceGroupName `
    --sku $Sku `
    --admin-enabled $AdminEnabled

  Throw-WhenError -output $output
}