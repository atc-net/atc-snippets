function Lock-Resource {
  # Lock creation needs the service principal to have access: Microsoft.Authorization/locks/write
  # Find resourcetypes: https://docs.microsoft.com/en-us/azure/templates/
  # The name of the locks will be the same as the locktype
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ResourceName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ResourceType,

    [Parameter(Mandatory = $true)]
    [ValidateSet("CanNotDelete", "ReadOnly")]
    [string]
    $LockType
  )

  Write-Host "  Creating '$LockType' lock for resource '$ResourceName' in '$ResourceGroupName'" -ForegroundColor DarkYellow
  $output = az lock create `
    --name $LockType `
    --resource-group $ResourceGroupName `
    --resource $ResourceName `
    --lock-type $LockType `
    --resource-type $ResourceType

  Throw-WhenError -output $output
}

