function Set-LoginAccount {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $subscriptionId
  )

  if ((Test-Path env:servicePrincipalId)) {
    Write-Host "Logged in through DevOps AZ CLI" -ForegroundColor White
  }
  else {
    az login --allow-no-subscriptions
  }

  az account set --subscription $subscriptionId
}