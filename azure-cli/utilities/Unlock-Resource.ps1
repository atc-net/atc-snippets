function Unlock-Resource {
  # Lock deletion needs the service principal to have access: Microsoft.Authorization/locks/write
  # Find resourcetypes: https://docs.microsoft.com/en-us/azure/templates/
  # The name of the locks should be the same as the locktype
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
  
  Write-Host "  Removing '$LockType' lock for resource '$ResourceName' in '$ResourceGroupName'" -ForegroundColor DarkYellow
  $output = az lock delete `
      --name $LockType `
      --resource-group $ResourceGroupName `
      --resource $ResourceName `
      --resource-type $ResourceType

  Throw-WhenError -output $output
}
