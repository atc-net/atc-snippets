function Set-LoginAccount {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $subscriptionId
    )
    az login --allow-no-subscriptions
    az account set --subscription $subscriptionId
}