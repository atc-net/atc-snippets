param (
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $resourceGroupName,

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
# import utility functions
. "$PSScriptRoot\add_Lock.ps1"

#############################################################################################
# Provision resource group
#############################################################################################
Write-Host "Provision resource group" -ForegroundColor DarkGreen

Write-Host "  Creating resource group $resourceGroupName" -ForegroundColor DarkYellow
$output = az group create `
  --name $resourceGroupName `
  --location $location `
  --tags $resourceTags

Throw-WhenError -output $output

#############################################################################################
# Add resource group lock
#############################################################################################
Add-Lock $resourceGroupName "LockGroup"