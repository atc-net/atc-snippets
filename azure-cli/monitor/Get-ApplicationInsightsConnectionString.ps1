function Get-ApplicationInsightsConnectionString {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $InsightsName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ResourceGroupName
  )

  Write-Host " Getting Application Insights '$InsightsName' ConnectionString" -ForegroundColor DarkYellow
  $connectionString = az monitor app-insights component show `
    --app $InsightsName `
    --resource-group $ResourceGroupName `
    --query connectionString `
    --output tsv

  Throw-WhenError -output $connectionString

  return $connectionString
}