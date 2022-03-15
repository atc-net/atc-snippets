param (
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $resourceGroupName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $mlWorkspaceName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $dataLakeName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $insightsName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $keyVaultName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $registryName,

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
. "$PSScriptRoot\..\monitor\get_ApplicationInsightsId.ps1"
. "$PSScriptRoot\..\storage\get_StorageAccountId.ps1"
. "$PSScriptRoot\..\keyvault\get_KeyVaultId.ps1"
. "$PSScriptRoot\..\acr\get_ContainerRegistryId.ps1"

#############################################################################################
# Resource naming section
#############################################################################################
$dataLakeId = Get-StorageAccountId  $dataLakeName $resourceGroupName
$insightsId = Get-ApplicationInsightsId $insightsName $resourceGroupName
$keyVaultId = Get-KeyVaultId $keyVaultName $resourceGroupName
$registryId = Get-ContainerRegistryId $registryName $resourceGroupName

###############################################################################################
# Provision Azure Machine Learning Workspace resource
###############################################################################################

Write-Host "  Provision Azure Machine Learning Workspace" -ForegroundColor DarkYellow

Write-Host "  Creating the Machine Learning workspace"

$workspaceDef = "name: $($mlWorkspaceName)
location: $($location)
description: Description of my workspace
storage_account: $($dataLakeId)
container_registry: $($registryId)
key_vault: $($keyVaultId)
application_insights: $($insightsId)"

Set-Content -Path "$PSScriptRoot\workspace.yml" -Value $workspaceDef

$output = az ml workspace create `
  -w $mlWorkspaceName `
  -g $resourceGroupName `
  --file "$PSScriptRoot\workspace.yml"

Throw-WhenError -output $output