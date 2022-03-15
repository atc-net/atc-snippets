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
    
  Write-Host "  Creating Application Insights '$AppServicePlanName'" -ForegroundColor DarkYellow
  
  $instrumentationKey = az monitor app-insights component create `
    --app $InsightsName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --application-type web `
    --kind web `
    --workspace $logAnalyticsId `
    --tags $resourceTags `
    --query instrumentationKey `
    --output tsv
  
  Throw-WhenError -output $instrumentationKey

  return $instrumentationKey
}