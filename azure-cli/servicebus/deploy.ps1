<#
  .SYNOPSIS
  Deploys Azure Service Bus Namespace

  .DESCRIPTION
  The deploy.ps1 script deploys an Azure Service Bus Namespace instance using the CLI tool to a resource group in the relevant environment.

  .PARAMETER environmentType
  Specifies the environment type. Staging (DevTest) or production

  .PARAMETER location
  Specifies the location where the services are deployed. Default is West Europe

  .PARAMETER resourceGroupName
  Specifies the name of the resource group

  .PARAMETER serviceBusName
  Specifies the name of the service bus namespace

  .PARAMETER logAnalyticsId
  Specifies the id for the log analytics workspace

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
  $serviceBusName,

  [Parameter(Mandatory=$true)]
  [string]
  $logAnalyticsId,

  [Parameter(Mandatory = $false)]
  [string[]] $resourceTags = @()
)

#############################################################################################
# Provision Service Bus Namespace
#############################################################################################
Write-Host "Provision Service Bus" -ForegroundColor DarkGreen

Write-Host "  Creating Service Bus" -ForegroundColor DarkYellow
$serviceBusId = az servicebus namespace create `
  --resource-group $resourceGroupName `
  --name $serviceBusName `
  --location $location `
  --sku Standard `
  --tags $resourceTags `
  --query id

Throw-WhenError -output $serviceBusId

Write-Host "  Configuring Send/Listen access policy" -ForegroundColor DarkYellow
$output = az servicebus namespace authorization-rule create `
	--resource-group $resourceGroupName `
	--namespace-name $serviceBusName `
	--name 'SendListenAccessKey' `
	--rights Listen Send

Throw-WhenError -output $output

Write-Host "  Provision Service Bus Topics" -ForegroundColor DarkYellow
Foreach ($topic in @(
	'events'
	))
{
	Write-Host "    Provisioning topic $topic" -ForegroundColor DarkYellow
	$output = az servicebus topic create `
		--resource-group $resourceGroupName `
		--namespace-name $serviceBusName `
		--name $topic

	Throw-WhenError -output $output
}

Write-Host "  Creating Diagnostic Settings for all logs and metrics" -ForegroundColor DarkYellow
$output = az monitor diagnostic-settings create `
  --name 'log-analytics' `
  --resource $serviceBusId `
  --logs '[{\"category\": \"OperationalLogs\",\"enabled\": true}]' `
  --metrics '[{\"category\": \"AllMetrics\",\"enabled\": true}]' `
  --workspace $logAnalyticsId

Throw-WhenError -output $output
