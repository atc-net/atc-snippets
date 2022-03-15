param (
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $resourceGroupName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $logAnalyticsName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $insightsName,

  [Parameter(Mandatory = $false)]
  [string]
  $location = "westeurope",

  [Parameter(Mandatory = $false)]
  [string[]]
  $resourceTags = @()
)

#############################################################################################
# Provision log analytics resource
#############################################################################################
Write-Host "Provision Log Analytics Workspace" -ForegroundColor DarkGreen

$logAnalyticsId = az monitor log-analytics workspace create `
  --workspace-name $logAnalyticsName `
  --location $location `
  --resource-group $resourceGroupName `
  --tags $resourceTags `
  --query id

Throw-WhenError -output $logAnalyticsId

#############################################################################################
# Provision application insights resource
#############################################################################################
Write-Host "Provision application insights" -ForegroundColor DarkGreen

Write-Host "  Creating application insights" -ForegroundColor DarkYellow
$output = az monitor app-insights component create `
  --app $insightsName `
  --location $location `
  --resource-group $resourceGroupName `
  --application-type web `
  --kind web `
  --workspace $logAnalyticsId `
  --tags $resourceTags

Throw-WhenError -output $output