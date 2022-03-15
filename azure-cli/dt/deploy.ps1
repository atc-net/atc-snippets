param (
  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [ValidateSet('DevTest', 'Production')]
  [string]
  $environmentType = "DevTest",

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $resourceGroupName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $digitalTwinsName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $eventHubNamespaceName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $eventHubName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $authorisationRuleName,

  [Parameter(Mandatory = $false)]
  [string]
  $location = "westeurope",

  [Parameter(Mandatory = $false)]
  [string[]]
  $resourceTags = @(),

  [Parameter(Mandatory = $false)]
  [string[]]
  $developerIdentities = @()
)

#############################################################################################
# Provision Digital Twins Instance
#############################################################################################
Write-Host "Provision Digital Twins Instance" -ForegroundColor DarkGreen

Write-Host "  Query Digital Twins Instance" -ForegroundColor DarkYellow
$output = az dt show `
  --dt-name $digitalTwinsName `
  --resource-group $resourceGroupName

if (!$?) {
  Write-Host "  Creating Digital Twins Instance" -ForegroundColor DarkYellow
  $output = az dt create `
    --resource-group $resourceGroupName `
    --dt-name $digitalTwinsName `
    --location $location `
    --assign-identity true `
    --tags $resourceTags

  Throw-WhenError -output $output

  if ($environmentType -eq 'DevTest') {
    for ($i = 0; $i -lt $developerIdentities.Count; $i++) {
      Write-Host "  Assigning 'Azure Digital Twins Data Owner' Role for developer $($i+1)" -ForegroundColor DarkYellow
      $output = az dt role-assignment create `
        --dt-name $digitalTwinsName `
        --resource-group $resourceGroupName `
        --assignee $developerIdentities[$i] `
        --role "Azure Digital Twins Data Owner"

      Throw-WhenError -output $output
    }
  }
}
else {
  Write-Host "  Digital Twin already exists, skipping creation" -ForegroundColor DarkYellow
}

Throw-WhenError -output $output
Write-Host "  Adding eventHub endpoint and routes to Digital Twins instance '$digitalTwinsName'" -ForegroundColor DarkYellow

Write-Host "  Creating twins hub endpoint for eventHub $eventHub" -ForegroundColor DarkYellow
$output = az dt endpoint create eventhub `
  --dt-name $digitalTwinsName `
  --endpoint-name "$eventHubName-endpoint" `
  --eventhub-resource-group $resourceGroupName `
  --eventhub-namespace $eventHubNamespaceName `
  --eventhub $eventHubName `
  --eventhub-policy $authorisationRuleName

Throw-WhenError -output $output

Write-Host "  Querying twins hub endpoint provisioning status for $eventHub" -ForegroundColor DarkYellow
$output = az dt endpoint show `
  --dt-name $digitalTwinsName `
  --endpoint-name "$eventHubName-endpoint" `
  --resource-group $resourceGroupName `
  --query properties.provisioningState `
  -o tsv

Throw-WhenError -output $output

if ("Provisioning" -eq $output) {
  Write-Host "  Waiting on Digital Twins endpoint post-provisioning" -ForegroundColor DarkYellow
  Start-Sleep -Seconds 20
}

Write-Host "  Creating twins hub event route for eventHub $eventHubName" -ForegroundColor DarkYellow
$output = az dt route create `
  --dt-name $digitalTwinsName `
  --endpoint-name "$eventHubName-endpoint" `
  --route-name "$eventHubName-route" `
  --filter "type = 'Microsoft.DigitalTwins.Twin.Update'"

Throw-WhenError -output $output