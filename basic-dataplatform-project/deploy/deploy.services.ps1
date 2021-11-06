<#
  .SYNOPSIS
  Deploys Azure services with the Azure CLI tool

  .DESCRIPTION
  The deploy.ps1 script deploys Azure service using the CLI tool to a resource group in the relevant environment.

  .PARAMETER environmentConfig
  Specifies the environment configuration

  .PARAMETER namingConfig
  Specifies the configuration element used to build the resource names for the resource group and the services

  .PARAMETER resourceTags
  Specifies the tag elements that will be used to tag the deployed services

  .INPUTS
  None. You cannot pipe objects to deploy.ps1.

  .OUTPUTS
  None. deploy.ps1 does not generate any output.
#>
param (
  [Parameter(Mandatory = $false)]
  [string] $tenantId,

  [Parameter(Mandatory = $false)]
  [string] $clientId,

  [Parameter(Mandatory = $true)]
  [EnvironmentConfig] $environmentConfig,

  [Parameter(Mandatory = $true)]
  [NamingConfig] $namingConfig,

  [Parameter(Mandatory = $false)]
  [string[]] $resourceTags = @()
)

#############################################################################################
# Configure names and options
#############################################################################################

# import utility functions
. "$PSScriptRoot\utilities\deploy.utilities.ps1"
. "$PSScriptRoot\utilities\deploy.naming.ps1"
. "$PSScriptRoot\keyvault\get_KeyVaultSecret.ps1"

# Install required extensions
. "$PSScriptRoot\extensions.ps1"

if (!$tenantId) {
  $tenantId = (az account show --query tenantId).Replace('"','')
}

if (!$clientId) {
  $clientId = (az account show --query user.name).Replace('"','')
}

#############################################################################################
# Resource naming section
#############################################################################################

# ISS provisioned Resource Names
$resourceGroupName      = Get-ResourceGroupName -environmentConfig $environmentConfig -namingConfig $namingConfig
$keyVaultName           = Get-KeyVaultName -environmentConfig $environmentConfig -namingConfig $namingConfig

# Resource Names
$databricksName         = Get-ResourceName -environmentConfig $environmentConfig -namingConfig $namingConfig -suffix 'dbw'

# Write setup
Write-Host "**********************************************************************" -ForegroundColor White
Write-Host "* Environment name                 : $($environmentConfig.EnvironmentName)" -ForegroundColor White
Write-Host "* Resource group name              : $resourceGroupName" -ForegroundColor White
Write-Host "* Key vault name                   : $keyVaultName" -ForegroundColor White
Write-Host "* Databricks workspace             : $databricksName" -ForegroundColor White
Write-Host "**********************************************************************" -ForegroundColor White

#############################################################################################
# Keyvault section
#############################################################################################
Write-Host "Get Key Vault secrets" -ForegroundColor DarkGreen

$objectId = Get-KeyVaultSecret -keyVaultName $keyVaultName -secretName ""

# Get SPN certificate which we will need for databricks
$certificateAsBase64 = Get-KeyVaultSecret -keyVaultName $keyVaultName -secretName ""
$certificatePassword = Get-KeyVaultSecret -keyVaultName $keyVaultName -secretName ""
$certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList (
  [System.Convert]::FromBase64String($certificateAsBase64), 
  $certificatePassword
)

#############################################################################################
# Provision Databricks
#############################################################################################
& "$PSScriptRoot\databricks\deploy.ps1" `
  -tenantId $tenantId `
  -resourceGroupName $resourceGroupName `
  -databricksName $databricksName `
  -objectId $objectId `
  -clientId $clientId `
  -certificate $certificate