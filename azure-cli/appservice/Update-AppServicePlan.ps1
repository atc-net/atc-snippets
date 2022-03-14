using module "./AppServicePlanSkuNames.psm1"

function Update-AppServicePlan {
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
    [string]
    $Location = "westeurope"
  )

  Write-Host "  Updating app service plan '$AppServicePlanName'" -ForegroundColor DarkYellow
  $appServicePlanId = az appservice plan update `
    --name $AppServicePlanName `
    --location $Location `
    --resource-group $ResourceGroupName `
    --sku $Sku `
    --query id

  Throw-WhenError -output $appServicePlanId
  
  return $appServicePlanId
}