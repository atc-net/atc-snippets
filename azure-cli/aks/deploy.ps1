<#
  .SYNOPSIS
  Deploys Azure Kubernetes Cluster (AKS)

  .DESCRIPTION
  The deploy.ps1 script deploys an Azure Kubernetes Cluster using Azure CLI to a resource group in the relevant environment.

  .PARAMETER environmentType
  Specifies the environment type. Staging (DevTest) or Production

  .PARAMETER environmentName
  Specifies the environment name. E.g. Dev, Test etc.

  .PARAMETER systemName
  Specifies the system name

  .PARAMETER location
  Specifies the location where the services are deployed. Default is West Europe

  .PARAMETER resourceGroupName
  Specifies the name of the resource group

    .PARAMETER logAnalyticsId
  Specifies the id of the Log Analytics workspace

  .PARAMETER aksClusterName
  Specifies the name of the Azure Kubernetes Cluster (AKS)

  .PARAMETER registryName
  Specifies the name of the Azure Container Registry service

  .PARAMETER clientId
  Specifies the id of the service principle

    .PARAMETER clientSecret
  Specifies the secret for the service principle

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

  [Parameter(Mandatory = $true)]
  [string]
  $environmentName,

  [Parameter(Mandatory = $true)]
  [string]
  $systemName,

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
  $aksClusterName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $logAnalyticsId,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $registryName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $clientId,

  [Parameter(Mandatory=$true)]
  [ValidateNotNullOrEmpty()]
  [Security.SecureString]
  $clientSecret,

  [Parameter(Mandatory = $false)]
  [string[]] $resourceTags = @()
)

#############################################################################################
# Provision AKS Cluster
#############################################################################################
Write-Host "Provision AKS Cluster" -ForegroundColor DarkGreen

Write-Host "  Creating AKS Cluster" -ForegroundColor DarkYellow
$output = az aks create `
  --name $aksClusterName `
  --resource-group $resourceGroupName `
  --location $location `
  --enable-managed-identity `
  --enable-addons monitoring `
  --workspace-resource-id $logAnalyticsId `
  --node-count 1 `
  --vm-set-type VirtualMachineScaleSets `
  --load-balancer-sku standard `
  --enable-cluster-autoscaler `
  --min-count 1 `
  --max-count 3 `
  --node-vm-size Standard_DS2_v2 `
  --no-ssh-key `
  --service-principal $clientId `
  --client-secret (ConvertTo-PlainText $clientSecret) `
  --tags `
    Env=$environmentName `
    System=$systemName

Throw-WhenError -output $output

Write-Host "  Attaching Container Registry to AKS Cluster" -ForegroundColor DarkYellow
$output = az aks update `
  --name $aksClusterName `
  --resource-group $resourceGroupName `
  --attach-acr $registryName

Throw-WhenError -output $output

$aksId = $(az aks show -n $aksClusterName -g $resourceGroupName -o tsv --query id)

#############################################################################################
# Connect resources with Azure Monitor
#############################################################################################
Write-Host "Connect resources with Azure Monitor" -ForegroundColor DarkGreen

Write-Host "  Creating Diagnostic Setting for AKS" -ForegroundColor DarkYellow
$aksMonitorLogging = Get-Content "$PSScriptRoot/aksmonitorlogging.json" -Raw
$aksMonitorLogging = $aksMonitorLogging -replace '\s+', '' -replace '"', '\"'

$aksMonitorMetrics = Get-Content "$PSScriptRoot/aksmonitormetrics.json" -Raw
$aksMonitorMetrics = $aksMonitorMetrics -replace '\s+', '' -replace '"', '\"'

$output = az monitor diagnostic-settings create `
  --resource $aksId `
  --name "AksToMonitorDiagnostics" `
  --workspace $logAnalyticsId `
  --resource-group $resourceGroupName `
  --logs $aksMonitorLogging `
  --metrics $aksMonitorMetrics

Throw-WhenError -output $output