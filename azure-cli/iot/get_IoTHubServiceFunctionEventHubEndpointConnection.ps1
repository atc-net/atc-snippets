function Get-IoTHubServiceFunctionEventHubEndpointConnection {
  param (
    [Parameter(Mandatory = $true)]
    [string]
    $iotHubName,

    [Parameter(Mandatory = $true)]
    [string]
    $iotHubSasPolicyNameFunctionApp,

    [Parameter(Mandatory = $true)]
    [string]
    $sasPolicyPrimaryFunctionKey
  )

  Write-Host "  Query for IoTHub EventHub Endpoint" -ForegroundColor DarkYellow
  $iotHubEventHubEndpoint = az iot hub show `
    --name $iotHubName `
    --query properties.eventHubEndpoints.events.endpoint `
    --output tsv

  Throw-WhenError -output $iotHubEventHubEndpoint

  return "Endpoint=" + $iotHubEventHubEndpoint + ";SharedAccessKeyName=" + $iotHubSasPolicyNameFunctionApp + ";SharedAccessKey=" + $sasPolicyPrimaryFunctionKey + ";EntityPath=" + $iotHubName;
}