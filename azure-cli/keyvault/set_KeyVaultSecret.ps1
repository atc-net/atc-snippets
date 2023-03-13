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

  . "$PSScriptRoot\get_KeyVaultSecret.ps1"
  . "$PSScriptRoot\recover_KeyVaultSecret.ps1"
  . "$PSScriptRoot\verify_KeyVaultSecret.ps1"

  Write-Host "  Setting $secretName secret" -ForegroundColor DarkYellow

  $alreadySet = Verify-KeyVaultSecret `
    -keyVaultName $keyVaultName `
    -secretName $secretName `
    -secretPlain $secretPlain

  if ($alreadySet) {
    Write-Host "  $secretName already has correct value" -ForegroundColor DarkYellow
    return
  }

  # On Windows systems, when passing the secret value to azure-cli and if the secrets has special characters,
  # it doesn't always correctly escape the argument and ends up intepreting the whole command wrong.
  # A fix is to wrap the $secretPlain in triple quotes and then it should work every time, on Windows.
  # On Linux we don't have this issue and if we add the triple quotes on Linux,
  # it will end up writing the secret value quoted into the key vault.
  #
  # Detect if we are running Windows and have to deal with this scenario.
  # Windows systems will always return "Win32NT" and Linux and Mac will return "Unix"
  if ([System.Environment]::OSVersion.Platform -eq 'Win32NT') {
    $secretPlain = """$secretPlain"""
  }

  # The loop below handles a number of different edge cases
  # that can occur when a secret has been soft deleted, and must first
  # be recovered before an new secret value can be written to it.
  while ($true) {
    $err = $( $output = az keyvault secret set `
        --vault-name $keyVaultName `
        --name $secretName `
        --value $secretPlain ) 2>&1

    if ($err) {
      if ($err -like "*Secret $secretName is currently in a deleted but recoverable state, and its name cannot be reused; in this state, the secret can only be recovered or purged.*") {
        Write-Host "  Secret was soft-deleted. Recovering $secretName secret" -ForegroundColor DarkYellow

        $output = Recover-KeyVaultSecret `
          -keyVaultName $keyVaultName `
          -secretName $secretName

        Throw-WhenError -output $err

        if ($secretPlain -eq $output) {
          Write-Host "  Recovered $secretName secret has correct value" -ForegroundColor DarkYellow
          break
        }
      }
      else {
        Throw-WhenError -output $err
      }
    }
    else {
      Write-Host "  $secretName secret set" -ForegroundColor DarkYellow
      break
    }
  }
}