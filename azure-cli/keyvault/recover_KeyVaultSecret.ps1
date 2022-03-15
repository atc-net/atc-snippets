function Recover-KeyVaultSecret {
  param (
    [Parameter(Mandatory = $true)]
    [string]
    $keyVaultName,

    [Parameter(Mandatory = $true)]
    [string]
    $secretName
  )

  Write-Host "    Recovering $secretName secret"

  $output = az keyvault secret recover `
    --vault-name $keyVaultName `
    --name $secretName

  Throw-WhenError -output $output

  while ($true) {
    $err = $( $output = az keyvault secret show `
        --name $secretName `
        --vault-name $keyVaultName `
        --query value `
        --output tsv ) 2>&1

    if ($err) {
      if ($err -like "*ERROR: (SecretNotFound)*") {
        Write-Host "    Secret is being recovered. Waiting one second"
        Start-Sleep -Seconds 1
      }
      else {
        Throw-WhenError -output $err
      }
    }
    else {
      break
    }
  }

  return $output
}