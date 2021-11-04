<#
  .SYNOPSIS
  Deploys Azure Synapse instance

  .DESCRIPTION
  The deploy.ps1 script deploys an Azure Synapse instance using Azure CLI to a resource group in the relevant environment.

  .PARAMETER location
  Specifies the location where the services are deployed. Default is West Europe

  .PARAMETER resourceGroupName
  Specifies the name of the resource group

  .PARAMETER synapseWorkspaceName
  Specifies the name of the Synapse workspace

  .PARAMETER storageAccountName
  Specifies the name of the storage account

  .PARAMETER keyVaultName
  Specifies the name of the key vault

  .PARAMETER resourceTags
  Specifies the tag elements that will be used to tag the deployed services

  .INPUTS
  None. You cannot pipe objects to deploy.ps1.

  .OUTPUTS
  None. deploy.ps1 does not generate any output.
#>
param (
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
  $synapseWorkspaceName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $storageAccountName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $keyVaultName,

  [Parameter(Mandatory = $false)]
  [string[]] $resourceTags = @()
)

#############################################################################################
# Configure names and options
#############################################################################################
Write-Host "Provision synapse workspace" -ForegroundColor DarkGreen

# import utility functions
. "$PSScriptRoot\..\_common\utilities\get_NewPassword.ps1"

#############################################################################################
# Resource naming section
#############################################################################################
$synapseAdminLoginUser = 'synapseadmin'
$storageContainer = "synapse"

#############################################################################################
# Configure key vault secrets
#############################################################################################
Write-Host "Configure key vault secrets " -ForegroundColor DarkGreen

Write-Host "  Querying SynapseServerPassword secret" -ForegroundColor DarkYellow
$synapseServerPassword = az keyvault secret show `
  --name 'SynapseServerPassword' `
  --vault-name $keyVaultName `
  --query value `
  --output tsv

if (!$?) {
  Write-Host "  Creating SynapseServerPassword secret" -ForegroundColor DarkYellow
  $synapseServerPassword = Get-NewPassword
  $output = az keyvault secret set `
    --vault-name $keyVaultName `
    --name "SynapseServerPassword" `
    --value $synapseServerPassword

  Throw-WhenError -output $output
}
else {
  Write-Host "  SynapseServerPassword already exists, skipping creation" -ForegroundColor DarkYellow
}

#############################################################################################
# Provision Synapse Workspace
#############################################################################################
Write-Host "Creating data lake container" -ForegroundColor DarkGreen
az storage fs create -n $storageContainer --account-name $storageAccountName

Write-Host "  Creating synapse workspace" -ForegroundColor DarkYellow

az synapse workspace create `
  --name $synapseWorkspaceName `
  --resource-group $resourceGroupName `
  --storage-account $storageAccountName `
  --file-system $storageContainer `
  --sql-admin-login-user $synapseAdminLoginUser `
  --sql-admin-login-password $synapseServerPassword `
  --location $location

#############################################################################################
# Provision Synapse SQL Pool
#############################################################################################
Write-Host "Provision Synapse SQL Pool" -ForegroundColor DarkGreen

az synapse sql pool create `
  --resource-group $resourceGroupName `
  --name sqlpool `
  --performance-level "DW1000c" `
  --workspace-name $synapseWorkspaceName