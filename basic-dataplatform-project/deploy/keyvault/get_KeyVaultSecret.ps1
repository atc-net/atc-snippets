function Get-KeyVaultSecret {
  param (
    [Parameter(Mandatory=$true)]
    [string]
    $keyVaultName,

    [Parameter(Mandatory=$true)]
    [string]
    $secretName
  )

  Write-Host "  Querying $secretName secret" -ForegroundColor DarkYellow
  $output = az keyvault secret show `
    --name $secretName `
    --vault-name $keyVaultName `
    --query value `
    --output tsv

  return $output
}