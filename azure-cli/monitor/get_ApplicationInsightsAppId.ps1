function Get-ApplicationInsightsAppId {
  param (
    [Parameter(Mandatory = $true)]
    [string]
    $name,

    [Parameter(Mandatory = $true)]
    [string]
    $resourceGroup
  )

  Write-Host "  Get application insight id" -ForegroundColor DarkYellow
  $appInsightAppId = az monitor app-insights component show `
    --app $name `
    --resource-group $resourceGroup `
    --query appId

  Throw-WhenError -output $appInsightAppId

  return $appInsightAppId
}