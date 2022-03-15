function Provision-ApplicationInsights {
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
  
  # import utility functions
  . "$PSScriptRoot\New-ApplicationInsights.ps1"

  Write-Host "Provision Application Insights '$InsightsName'" -ForegroundColor DarkGreen

  Write-Host "  Querying for existing Application Insights" -ForegroundColor DarkYellow -NoNewline
  $response = az monitor app-insights component show `
    --resource-group $ResourceGroupName `
    --query "[?name=='$InsightsName']|[0].{instrumentationKey: instrumentationKey}"

  if ($null -eq $response) {
    Write-Host " -> Resource not found." -ForegroundColor Cyan
    
    $instrumentationKey = New-ApplicationInsights `
      -Name $InsightsName `
      -LogAnalyticsId $LogAnalyticsId `
      -ResourceGroupName $ResourceGroupName `
      -Location $Location `
      -ResourceTags $ResourceTags
  }
  else {
    Write-Host " -> Resource exists." -ForegroundColor Cyan
    $instrumentationKey = ($response | ConvertFrom-Json -AsHashtable).instrumentationKey
  }

  return $instrumentationKey
}