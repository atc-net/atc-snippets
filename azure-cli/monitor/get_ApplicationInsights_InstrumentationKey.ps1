function Get-ApplicationInsightsInstrumentationKey {

    param (
      [Parameter(Mandatory=$true)]
      [string]
      $name,
  
      [Parameter(Mandatory=$true)]
      [string]
      $resourceGroup
    )
  
     Write-Host "Get instrumentation key" -ForegroundColor DarkYellow
     $instrumentationKey = az monitor app-insights component show `
      --app $name `
      --resource-group $resourceGroup `
      --query instrumentationKey
  
    Throw-WhenError -output $instrumentationKey
  
    return $instrumentationKey
  }