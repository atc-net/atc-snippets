function Get-LogAnalyticsKey {
  param (
    [Parameter(Mandatory = $true)]
    [string]
    $logAnalyticsName,

    [Parameter(Mandatory = $true)]
    [string]
    $resourceGroup
  )

  Write-Host "  Get log analytics key" -ForegroundColor DarkYellow
  $logAnalyticsKey = az monitor log-analytics workspace get-shared-keys `
    --workspace-name $logAnalyticsName `
    --resource-group $resourceGroup `
    --query primarySharedKey

  Throw-WhenError -output $logAnalyticsKey

  return $logAnalyticsKey
}