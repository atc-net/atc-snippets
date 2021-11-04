function Set-KeyVaultSecret {
  param (
    [Parameter(Mandatory = $true)]
    [string]
    $resourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]
    $keyVaultName,

    [Parameter(Mandatory = $true)]
    [string]
    $secretName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [securestring]
    $secret
  )

  $secretPlain = ConvertTo-PlainText -secret $secret

  Set-KeyVaultSecretPlain `
    -keyVaultName $keyVaultName `
    -resourceGroupName $resourceGroupName `
    -secretName $secretName `
    -secretPlain $secretPlain
}

function Set-KeyVaultSecretPlain {
  param (
    [Parameter(Mandatory = $true)]
    [string]
    $keyVaultName,

    [Parameter(Mandatory = $true)]
    [string]
    $resourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]
    $secretName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $secretPlain
  )

  $output = Get-KeyVaultSecret -keyVaultName $keyVaultName -secretName $secretName

  if ($secretPlain -ne $output) {

    Write-Host "  Creating $secretName secret" -ForegroundColor DarkYellow
    $output = az keyvault secret set `
      --vault-name $keyVaultName `
      --name $secretName `
      --value $secretPlain

    Throw-WhenError -output $output

  }
  else {
    Write-Host "  $secretName already exists, skipping creation" -ForegroundColor DarkYellow
  }
}