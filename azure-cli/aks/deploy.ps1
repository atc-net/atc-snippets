param (
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

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [Security.SecureString]
  $clientSecret,

  [Parameter(Mandatory = $false)]
  [string]
  $location = "westeurope",

  [Parameter(Mandatory = $false)]
  [string[]]
  $resourceTags = @()
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
  --tags $resourceTags `

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