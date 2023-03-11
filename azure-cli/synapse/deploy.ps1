param (
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
  [string]
  $location = "westeurope",

  [Parameter(Mandatory = $false)]
  [string[]]
  $resourceTags = @()
)

#############################################################################################
# Configure names and options
#############################################################################################
Write-Host "Provision synapse workspace" -ForegroundColor DarkGreen

# import utility functions
. "$PSScriptRoot\..\utilities\New-Password.ps1"

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
  $synapseServerPassword = New-Password -Length 20
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