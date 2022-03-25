
function Confirm-WebAppCors {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [Alias("Name", "AppName")]
    [string]
    $WebAppName,
  
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    $AllowedOrigins,
  
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ResourceGroupName
  )
  
  $output = az webapp cors show `
    --name $WebAppName `
    --resource-group $ResourceGroupName `
    --query "allowedOrigins"
  
  Throw-WhenError -output $output
  
  $existingAllowedOrigins = $output | ConvertFrom-Json
  
  return !($null -eq $existingAllowedOrigins -or `
    (Compare-Object $existingAllowedOrigins $AllowedOrigins))
}