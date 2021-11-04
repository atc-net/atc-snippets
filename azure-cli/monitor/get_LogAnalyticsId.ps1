function Get-LogAnalyticsId {
  param (
    [Parameter(Mandatory = $true)]
    [string]
    $logAnalyticsName,

    [Parameter(Mandatory = $true)]
    [string]
    $resourceGroup
  )

  Write-Host "  Get log analytics id" -ForegroundColor DarkYellow
  $logAnalyticsId = az monitor log-analytics workspace show `
    --workspace-name $logAnalyticsName `
    --resource-group $resourceGroup `
    --query id

  Throw-WhenError -output $logAnalyticsId

  return $logAnalyticsId
}