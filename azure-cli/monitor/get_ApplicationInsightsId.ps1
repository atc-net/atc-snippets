function Get-ApplicationInsightsId {
  param (
    [Parameter(Mandatory=$true)]
    [string]
    $name,

    [Parameter(Mandatory=$true)]
    [string]
    $resourceGroup
  )

  Write-Host "Get application insight id" -ForegroundColor DarkYellow
  $appInsightId = az monitor app-insights component show `
    --app $name `
    --resource-group $resourceGroup `
    --query id

  Throw-WhenError -output $appInsightId

  return $appInsightId
}