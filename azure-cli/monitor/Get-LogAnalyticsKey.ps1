function Get-LogAnalyticsKey {
  param (
    [Parameter(Mandatory = $true)]
    [string]
    $LogAnalyticsName,

    [Parameter(Mandatory = $true)]
    [string]
    $ResourceGroupName
  )

  Write-Host "  Getting Log Analytics key" -ForegroundColor DarkYellow
  
  $logAnalyticsKey = az monitor log-analytics workspace get-shared-keys `
    --workspace-name $LogAnalyticsName `
    --resource-group $ResourceGroupName `
    --query primarySharedKey `
    --output tsv

  Throw-WhenError -output $logAnalyticsKey

  return $logAnalyticsKey
}