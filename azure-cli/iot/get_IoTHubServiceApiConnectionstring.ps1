function Get-IoTHubServiceApiConnectionString{
    param (
      [Parameter(Mandatory=$true)]
      [string]
      $iotHubName,

      [Parameter(Mandatory=$true)]
      [string]
      $iotHubSasPolicyNameWebApi,

      [Parameter(Mandatory=$true)]
      [string]
      $resourceGroupName
    )
    Write-Host "  Query for IoTHub SasPolicy" -ForegroundColor DarkYellow

    $sasPolicyPrimaryApiKey = az iot hub policy show `
    --hub-name $iotHubName `
    --name $iotHubSasPolicyNameWebApi `
    --resource-group $resourceGroupName `
    --query primaryKey `
    --output tsv

    Throw-WhenError -output $sasPolicyPrimaryApiKey

    return "HostName=" + $iotHubName + ".azure-devices.net;SharedAccessKeyName=" + $iotHubSasPolicyNameWebApi + ";SharedAccessKey=" + $sasPolicyPrimaryApiKey
  }