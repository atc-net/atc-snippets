<#
  .SYNOPSIS
  Deploys Azure resource groups and key vaults with the Azure CLI tool

  .DESCRIPTION
  The deploy.ps1 script deploys Azure resource groups and key vaults for an application with an environment resource group and a service recource group

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
Write-Host "Initialize deployment" -ForegroundColor DarkGreen

# import utility functions
. "$PSScriptRoot\utilities\deploy.utilities.ps1"
. "$PSScriptRoot\utilities\deploy.naming.ps1"
. "$PSScriptRoot\..\ad\new_ServiceSPN.ps1"
. "$PSScriptRoot\..\keyvault\set_KeyVaultSPNPolicy.ps1"

# Install required extensions
. "$PSScriptRoot\extensions.ps1"

#############################################################################################
# Resource naming section
#############################################################################################

$envResourceGroupName   = Get-ResourceGroupName -systemName $namingConfig.SystemName -environmentName $environmentConfig.EnvironmentName
$envKeyVaultName        = Get-ResourceName -environmentConfig $environmentConfig -namingConfig $namingConfig -environmentName $true

$resourceGroupName      = Get-ResourceGroupName -serviceName $namingConfig.ServiceName -systemName $namingConfig.SystemName -environmentName $environmentConfig.EnvironmentName
$keyVaultName           = Get-ResourceName -environmentConfig $environmentConfig -namingConfig $namingConfig

# Write setup

Write-Host "**********************************************************************" -ForegroundColor White
Write-Host "* Environment name                 : $($environmentConfig.EnvironmentName)" -ForegroundColor White
Write-Host "* Env. resource group name         : $envResourceGroupName" -ForegroundColor White
Write-Host "* Resource group name              : $resourceGroupName" -ForegroundColor White
Write-Host "**********************************************************************" -ForegroundColor White

#############################################################################################
# Provision resource groups
#############################################################################################

& "$PSScriptRoot\..\group\deploy.ps1" -resourceGroupName $envResourceGroupName -resourceTags $resourceTags
& "$PSScriptRoot\..\group\deploy.ps1" -resourceGroupName $resourceGroupName -resourceTags $resourceTags

#############################################################################################
# Provision Azure Key Vaults
#############################################################################################
& "$PSScriptRoot\..\keyvault\deploy.ps1" -resourceGroupName $envResourceGroupName -keyVaultName $envKeyVaultName -resourceTags $resourceTags
& "$PSScriptRoot\..\keyvault\deploy.ps1" -resourceGroupName $resourceGroupName -keyVaultName $keyVaultName -resourceTags $resourceTags

#############################################################################################
# Provision Service Principles
#############################################################################################
# Create service priniple and save info to environment key vault
New-ServiceSPN -companyHostName "company.com" -envResourceGroupName $envResourceGroupName -envKeyVaultName $envKeyVaultName `
-environmentConfig $environmentConfig `
-namingConfig $namingConfig

# Grant access to SPN to the service key vault
Set-KeyVaultSPNPolicy -resourceGroupName $resourceGroupName -envKeyVaultName $envKeyVaultName -keyVaultName $keyVaultName `
-environmentConfig $environmentConfig `
-namingConfig $namingConfig
