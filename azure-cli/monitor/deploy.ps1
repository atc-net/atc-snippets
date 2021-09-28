<#
  .SYNOPSIS
  Deploys a log analytics workspace and application insights

  .DESCRIPTION
  The deploy.ps1 script deploys a log analytics workspace and application insights using Azure CLI to a resource group in the relevant environment.

  .PARAMETER environmentType
  Specifies the environment type. Staging (DevTest) or Production

  .PARAMETER location
  Specifies the location where the services are deployed. Default is West Europe

  .PARAMETER resourceGroupName
  Specifies the name of the resource group

  .PARAMETER logAnalyticsName
  Specifies the name of the Log Analytics workspace

  .PARAMETER insightsName
  Specifies the name of the Application Insights

  .PARAMETER resourceTags
  Specifies the tag elements that will be used to tag the deployed services

  .INPUTS
  None. You cannot pipe objects to deploy.ps1.

  .OUTPUTS
  None. deploy.ps1 does not generate any output.
#>
param (
  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [ValidateSet('DevTest', 'Production')]
  [string]
  $environmentType = "DevTest",

  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string]
  $location = "westeurope",

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
  [string[]] $resourceTags = @()
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