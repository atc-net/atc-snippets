<#
  .SYNOPSIS
  Deploys Azure Key Vault

  .DESCRIPTION
  The deploy.ps1 script deploys an Azure Key Vault using Azure CLI to a resource group in the relevant environment.

  .PARAMETER environmentType
  Specifies the environment type. Staging (DevTest) or Production

  .PARAMETER environmentName
  Specifies the environment name. E.g. Dev, Test etc.

  .PARAMETER location
  Specifies the location where the services are deployed. Default is West Europe

  .PARAMETER resourceGroupName
  Specifies the name of the resource group

  .PARAMETER keyVaultName
  Specifies the name of the key vault

  .PARAMETER resourceTags
  Specifies the tag elements that will be used to tag the deployed services

  .PARAMETER developerIdentities
  Object IDs from Azure AD to grant access for developers to read key vault in Development/Dev environments. This should be replaced with a single Azure AD group where these identities/users a added

  .INPUTS
  None. You cannot pipe objects to deploy.ps1.

  .OUTPUTS
  None. deploy.ps1 does not generate any output.

  .EXAMPLE
  PS> .\deploy.ps1 -environmentType DevTest -environmentName Dev -resourceGroupName xxx-DEV-xxx -keyVaultName xxxxxxdevxxxkv
#>
param (
  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [ValidateSet('DevTest', 'Production')]
  [string]
  $environmentType = "DevTest",

  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string]
  $location = "westeurope",

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $resourceGroupName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $keyVaultName,

  [Parameter(Mandatory = $false)]
  [string[]] $resourceTags = @(),

  [Parameter(Mandatory = $false)]
  [string[]] $developerIdentities = @()
)

#############################################################################################
# Configure names and options
#############################################################################################
# import utility functions
. "$PSScriptRoot\get_KeyVaultSecret.ps1"
. "$PSScriptRoot\set_KeyVaultSecret.ps1"
. "$PSScriptRoot\set_KeyVaultSPNPolicy.ps1"

#############################################################################################
# Provision Key Vault
#############################################################################################
Write-Host "Provision Key Vault" -ForegroundColor DarkGreen

Write-Host "  Query Key Vault" -ForegroundColor DarkYellow
$output = az keyvault show `
  --name $keyVaultName `
  --resource-group $resourceGroupName `

if (!$?) {
  Write-Host "  Create key vault" -ForegroundColor DarkYellow
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
else {
  Write-Host "  Key vault already exists, skipping creation" -ForegroundColor DarkYellow
}

Throw-WhenError -output $output