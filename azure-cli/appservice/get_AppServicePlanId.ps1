function Get-AppServicePlanId {
  param (
    [Parameter(Mandatory = $true)]
    [string]
    $appServicePlanName,

    [Parameter(Mandatory = $true)]
    [string]
    $resourceGroup
  )

  Write-Host "  Querying app service plan id" -ForegroundColor DarkYellow
  $appServicePlanId = az appservice plan show `
    --name $appServicePlanName `
    --resource-group $resourceGroup `
    --query id

  Throw-WhenError -output $appServicePlanId

  return $appServicePlanId
}