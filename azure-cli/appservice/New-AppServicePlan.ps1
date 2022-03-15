using module "./AppServicePlanSkuNames.psm1"

function New-AppServicePlan {
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

  Write-Host "  Creating app service plan '$AppServicePlanName'" -ForegroundColor DarkYellow

  $dynamicParameters = @()
  if ($UseLinux) {
    # Host web app on Linux worker
    $dynamicParameters += "--is-linux"
  }

  $appServicePlanId = az appservice plan create `
    --name $AppServicePlanName `
    --location $Location `
    --resource-group $ResourceGroupName `
    --sku $Sku `
    --tags $ResourceTags `
    --query id `
    @dynamicParameters

  Throw-WhenError -output $appServicePlanId

  return $appServicePlanId
}