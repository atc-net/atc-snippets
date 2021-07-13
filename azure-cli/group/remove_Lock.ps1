function Remove-Lock {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $resourceGroupName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $lockName
    )

    $lockid = az lock show --name $lockName --resource-group $resourceGroupName  --output tsv --query id
    # Delete if found
    if (!$?) {
        $resourceLock = az lock delete --ids $lockid --output tsv
        Throw-WhenError -output $resourceLock
    }
}