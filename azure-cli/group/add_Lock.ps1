function Add-Lock {
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

    $resourceLock = az lock create --name $lockName --lock-type CanNotDelete --resource-group $resourceGroupName --output tsv
    Throw-WhenError -output $resourceLock
}