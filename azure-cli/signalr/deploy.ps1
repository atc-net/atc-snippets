param (
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $resourceGroupName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $signalRName,

  [Parameter(Mandatory = $true)]
  [ValidateSet('Default', 'Serverless', 'Classic')]
  [string]
  $serviceMode = "Default",

  [Parameter(Mandatory = $false)]
  [string]
  $location = "westeurope",

  [Parameter(Mandatory = $false)]
  [string[]]
  $resourceTags = @()
)

#############################################################################################
# Provision SignalR
#############################################################################################
Write-Host "Provision SignalR" -ForegroundColor DarkGreen

Write-Host "  Creating SignalR" -ForegroundColor DarkYellow
$output = az signalr create `
  --name $signalRName `
  --location $location `
  --resource-group $resourceGroupName `
  --sku Standard_S1 `
  --unit-count 1 `
  --allowed-origins * `
  --service-mode $serviceMode

Throw-WhenError -output $output