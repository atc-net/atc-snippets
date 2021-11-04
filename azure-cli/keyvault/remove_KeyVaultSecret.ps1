function Remove-KeyVaultSecret {
  param (
    [Parameter(Mandatory = $true)]
    [string]
    $secretId
  )
  Write-Host "  Removing '$secretId' secret" -ForegroundColor DarkYellow
  $output = az keyvault secret delete --id $secretId
  Throw-WhenError -output $output
}