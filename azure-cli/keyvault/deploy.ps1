param (
  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [ValidateSet('DevTest', 'Production')]
  [string]
  $environmentType = "DevTest",

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $resourceGroupName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $keyVaultName,

  [Parameter(Mandatory = $false)]
  [string]
  $location = "westeurope",

  [Parameter(Mandatory = $false)]
  [string[]]
  $resourceTags = @(),

  [Parameter(Mandatory = $false)]
  [string[]]
  $developerIdentities = @()
)

#############################################################################################
# Configure names and options
#############################################################################################
# import utility functions
. "$PSScriptRoot\get_KeyVaultSecret.ps1"
. "$PSScriptRoot\set_KeyVaultSecret.ps1"
. "$PSScriptRoot\set_KeyVaultSPNPolicy.ps1"
. "$PSScriptRoot\test_KeyVaultExists.ps1"

#############################################################################################
# Provision Key Vault
#############################################################################################
Write-Host "Provision Key Vault" -ForegroundColor DarkGreen

if ((Test-KeyVaultExists -keyVaultName $keyVaultName -resourceGroupName $resourceGroupName) -eq $false) {
  Write-Host "  Creating key Vault $keyVaultName" -ForegroundColor DarkYellow
  $output = az keyvault create `
    --name $keyVaultName `
    --location $location `
    --resource-group $resourceGroupName `
    --sku 'standard' `
    --enabled-for-template-deployment true `
    --tags $resourceTags

  Throw-WhenError -output $output

  if ($environmentType -eq 'DevTest') {
    for ($i = 0; $i -lt $developerIdentities.Count; $i++) {
      Write-Host "  Grant access for developer $($i+1)" -ForegroundColor DarkYellow
      $output = az keyvault set-policy `
        --name $keyVaultName `
        --resource-group $resourceGroupName `
        --object-id $developerIdentities[$i] `
        --secret-permissions list get set delete

      Throw-WhenError -output $output
    }
  }
}

Throw-WhenError -output $output