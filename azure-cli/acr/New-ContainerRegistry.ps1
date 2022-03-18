using module "./ContainerRegistrySkuNames.psm1"

function New-ContainerRegistry {
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

  Write-Host "  Creating container registry '$ContainerRegistryName'" -ForegroundColor DarkYellow

  $loginServer = az acr create `
    --name $ContainerRegistryName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --sku $Sku `
    --admin-enabled $AdminEnabled `
    --tags $ResourceTags `
    --query loginServer `
    --output tsv

  Throw-WhenError -output $loginServer

  return $loginServer
}