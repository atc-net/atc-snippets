function Verify-KeyVaultSecret {
  param (
    [Parameter(Mandatory = $true)]
    [string]
    $keyVaultName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $secretName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $secretPlain
  )

  $err = $( $output = az keyvault secret show `
      --name $secretName `
      --vault-name $keyVaultName `
      --query value `
      --output tsv ) 2>&1

  if ($output -eq $secretPlain) {
    return $true
  }
  elseif ($err -like "*(SecretNotFound)*" -or $output -ne $secretPlain) {
    return $false
  }

  Throw-WhenError -output $err
}
