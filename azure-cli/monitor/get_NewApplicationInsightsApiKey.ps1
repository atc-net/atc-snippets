# This function deltes and re-creates the api key if it exists
# It is not possible to get an existing api key secret from azure
# if you need idempotence you need to wrap this function in extra logic
function Get-NewApplicationInsightsApiKey {
  param (
    [Parameter(Mandatory = $true)]
    [string]
    $name,

    [Parameter(Mandatory = $true)]
    [string]
    $resourceGroup,

    [Parameter(Mandatory = $true)]
    [string]
    $apiKeyName,

    [Parameter(Mandatory = $false)]
    [string]
    $readProperties="ReadTelemetry",

    [Parameter(Mandatory = $false)]
    [string]
    $writeProperties='""'

  )
  Write-Host "  Get new application insight apiKey" -ForegroundColor DarkYellow
  Write-Host "    check existing api-key" -ForegroundColor DarkYellow
  $oldApiKey = az monitor app-insights api-key show `
    --app $name `
    --resource-group $resourceGroup `
    --api-key $apiKeyName

  if($oldApiKey.length -gt 0){
    Write-Host "    delete existing api-key" -ForegroundColor DarkYellow
    $oldApiKey = az monitor app-insights api-key delete `
        --app $name `
        --resource-group $resourceGroup `
        --api-key $apiKeyName
    Throw-WhenError -output $oldApiKey
  }

  Write-Host "    create new api-key" -ForegroundColor DarkYellow
  $apiKey = az monitor app-insights api-key create `
              --app $name `
              --resource-group $resourceGroup `
              --api-key $apiKeyName `
              --read-properties $readProperties `
              --write-properties $writeProperties `
              --query apiKey

  Throw-WhenError -output $apiKey

  return $apiKey
}