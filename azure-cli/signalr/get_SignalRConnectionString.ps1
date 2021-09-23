function Get-SignalRConnectionString {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $resourceGroupName,
        [Parameter(Mandatory = $true)]
        [string]
        $signalRName
    )

    Write-Host "Getting SignalR account key" -ForegroundColor DarkYellow
    $signalRKey = az signalr key list `
        --name $signalRName `
        --resource-group $resourceGroupName `
        --query primaryKey

    Throw-WhenError -output $signalRKey

    return "Endpoint=https://" + $signalRName + ".service.signalr.net;AccessKey=" + $signalRKey + ";Version=1.0"
}