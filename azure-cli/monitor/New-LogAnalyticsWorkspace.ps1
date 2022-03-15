function New-LogAnalyticsWorkspace {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [Alias("Name")]
    [string]
    $LogAnalyticsName,

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
  
  Write-Host "  Creating Log Analytics Workspace '$AppServicePlanName'" -ForegroundColor DarkYellow

  $logAnalyticsId = az monitor log-analytics workspace create `
    --workspace-name $LogAnalyticsName `
    --location $Location `
    --resource-group $ResourceGroupName `
    --tags $ResourceTags `
    --query id `
    --output tsv

  Throw-WhenError -output $logAnalyticsId

  return $logAnalyticsId
}