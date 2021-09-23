function Add-DataLakeRoutingEndpoint{
    param (
      [Parameter(Mandatory=$true)]
      [string]
      $iotHubName,

      [Parameter(Mandatory=$true)]
      [string]
      $subscriptionId,

      [Parameter(Mandatory=$true)]
      [string]
      $storageConnectionString,

      [Parameter(Mandatory=$true)]
      [string]
      $resourceGroup
    )

    $routeExist = az iot hub route test -g $resourceGroup `
        --hub-name $iotHubName `
        --route-name data-lake-routing `
        --query result

    if ($routeExist) {
      Write-Host "  Deleting old IoTHub to data lake route" -ForegroundColor DarkYellow
      $output = az iot hub route delete `
        --name data-lake-routing `
        --hub-name $iotHubName `
        --resource-group $resourceGroup

      Write-Host "  Deleting old IoTHub to data lake routing-endpoint" -ForegroundColor DarkYellow
      Throw-WhenError $output
      $output = az iot hub routing-endpoint delete `
        --endpoint-name data-lake-storage `
        --resource-group $resourceGroup `
        --hub-name $iotHubName

      Throw-WhenError $output

      Write-Host "  Recreating IoTHub to data lake routing-endpoint" -ForegroundColor DarkYellow
      Start-Sleep -s 5

      $output = az iot hub routing-endpoint create `
        --connection-string $storageConnectionString `
        --endpoint-name data-lake-storage `
        --endpoint-resource-group $resourceGroup `
        --endpoint-subscription-id $subscriptionId `
        --endpoint-type azurestoragecontainer `
        --hub-name $iotHubName `
        --container delivery `
        --resource-group $resourceGroup `
        --encoding avro

      Throw-WhenError $output

      Write-Host "  Recreating IoTHub to data lake route" -ForegroundColor DarkYellow
      $output = az iot hub route create `
        --name data-lake-routing `
        --hub-name $iotHubName `
        --source devicemessages `
        --resource-group $resourceGroup `
        --endpoint-name data-lake-storage `
        --enabled `
        --condition true

      Throw-WhenError $output

    } else {
      Write-Host "  Adding IoTHub to data lake routing" -ForegroundColor DarkYellow
      
      Write-Host "  Creating IoTHub to data lake routing-endpoint." -ForegroundColor DarkYellow
      $output = az iot hub routing-endpoint create `
        --connection-string $storageConnectionString `
        --endpoint-name data-lake-storage `
        --endpoint-resource-group $resourceGroup `
        --endpoint-subscription-id $subscriptionId `
        --endpoint-type azurestoragecontainer `
        --hub-name $iotHubName `
        --container delivery `
        --resource-group $resourceGroup `
        --encoding avro

      Throw-WhenError $output

      Write-Host " Creating IoTHub to data lake route." -ForegroundColor DarkYellow
      $output = az iot hub route create `
        --name data-lake-routing `
        --hub-name $iotHubName `
        --source devicemessages `
        --resource-group $resourceGroup `
        --endpoint-name data-lake-storage `
        --enabled `
        --condition true

      Throw-WhenError $output

      Write-Host " Creating IoTHub to data lake route." -ForegroundColor DarkYellow
      $output = az iot hub route create `
        --name Eventhub `
        --hub-name $iotHubName `
        --source devicemessages `
        --resource-group $resourceGroup `
        --endpoint-name events `
        --enabled `
        --condition true

      Throw-WhenError $output
    }
}