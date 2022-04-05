function New-ApplicationInsights {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [Alias("Name")]
    [string]
    $InsightsName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $LogAnalyticsId,
  
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ResourceGroupName,
  
    [Parameter(Mandatory = $false)]
    [string]
    $Location = "westeurope",
  
    [Parameter(Mandatory = $false)]
    [string[]] 
    $ResourceTags = @()
  )
    
  Write-Host "  Creating Application Insights '$InsightsName'" -ForegroundColor DarkYellow
  
  $connectionString = az monitor app-insights component create `
    --app $InsightsName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --application-type web `
    --kind web `
    --workspace $logAnalyticsId `
    --tags $resourceTags `
    --query connectionString `
    --output tsv
  
  Throw-WhenError -output $connectionString

  return $connectionString
}