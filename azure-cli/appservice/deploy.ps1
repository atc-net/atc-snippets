<#
  .SYNOPSIS
  Deploys Azure app service plan

  .DESCRIPTION
  The deploy.ps1 script deploys an Azure app service plan using the CLI tool to a resource group in the relevant environment.

  .PARAMETER environmentType
  Specifies the environment type. Staging (DevTest) or production

  .PARAMETER environmentName
  Specifies the environment name. E.g. Dev, Test etc.

  .PARAMETER location
  Specifies the location where the services are deployed. Default is West Europe

  .PARAMETER resourceGroupName
  Specifies the name of the resource group

  .PARAMETER appServicePlanName
  Specifies the name of the app service plan

  .PARAMETER resourceTags
  Specifies the tag elements that will be used to tag the deployed services

  .INPUTS
  None. You cannot pipe objects to deploy.ps1.

  .OUTPUTS
  None. Udeploy.ps1 does not generate any output.

  .EXAMPLE
  PS> .\deploy.ps1 -environmentType DevTest -environmentName Dev -resourceGroupName xxx-DEV-xxx -appServicePlanName xxxxxxdevxxxplan
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
  $appServicePlanName,

  [Parameter(Mandatory = $false)]
  [string[]] $resourceTags = @()
)

#############################################################################################
# Provision app service plan
#############################################################################################
Write-Host "Provision app service plan" -ForegroundColor DarkGreen

$sku = 'S1'
if ($environmentType -eq 'Production') {
  $sku = 'P1V2'
}
Write-Host "  Create app service plan" -ForegroundColor DarkYellow
$appServicePlanId = az appservice plan create `
  --name $appServicePlanName `
  --location $location `
  --resource-group $resourceGroupName `
  --sku $sku `
  --tags $resourceTags `
  --query id
  Throw-WhenError -output $appServicePlanId