function Set-WebAppCors {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [Alias("Name", "AppName")]
    [string]
    $WebAppName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ResourceGroupName,

    [Parameter(Mandatory = $false)]
    [string[]]
    $AllowedOrigins
  )

  Write-Host "  Verifying cross-origin resource sharing (CORS)" -ForegroundColor DarkYellow -NoNewline
  $output = az webapp cors show `
    --name $WebAppName `
    --resource-group $ResourceGroupName `
    --query "allowedOrigins"

  Throw-WhenError -output $output

  $existingAllowedOrigins = $output | ConvertFrom-Json

  if ($AllowedOrigins.Count -eq 0) {
    if ($null -eq $existingAllowedOrigins) {
      Write-Host " -> CORS is not set, as intended." -ForegroundColor Cyan
    }
    else {
      Write-Host " -> CORS is set, but is not intended." -ForegroundColor Cyan
      Write-Host "  Removing Allowed Origins '$existingAllowedOrigins'" -ForegroundColor DarkYellow
      $output = az webapp cors remove `
        --name $WebAppName `
        --resource-group $ResourceGroupName `
        --allowed-origins
    }
  }
  else {
    if ($null -eq $existingAllowedOrigins -or `
      (Compare-Object $existingAllowedOrigins $AllowedOrigins)) {
      Write-Host " -> CORS changes detected." -ForegroundColor Cyan
      Write-Host "  Setting CORS Allowed Origins to '$AllowedOrigins'" -ForegroundColor DarkYellow

      # If allowed-origins is a wildcard, we have to wrap and escape the wildcard for it to also work with az cli on Linux.
      $wildcardIndex = $AllowedOrigins.IndexOf("*")
      if ($wildcardIndex -ge 0) {
        $AllowedOrigins[$wildcardIndex] = "`"`*`""
      }

      # Remove all existing allowed-origins.
      $output = az webapp cors remove `
        --name $WebAppName `
        --resource-group $ResourceGroupName `
        --allowed-origins

      Throw-WhenError -output $output

      # Set the new allowed-origins
      $output = az webapp cors add `
        --name $WebAppName `
        --resource-group $ResourceGroupName `
        --allowed-origins $AllowedOrigins

      Throw-WhenError -output $output
    }
    else {
      Write-Host " -> CORS is correctly configured." -ForegroundColor Cyan
    }
  }
}