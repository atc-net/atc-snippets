function Get-IotHubEventhubCompatibleEndpoint
{
  param (
    [Parameter(Mandatory=$true)]
    [string]
    $iotHubName
  )
  
  $endpoint = az iot hub connection-string show -n $iotHubName --default-eventhub --policy-name iothubowner --query connectionString --output tsv

  Throw-WhenError -output $endpoint

  return $endpoint
}