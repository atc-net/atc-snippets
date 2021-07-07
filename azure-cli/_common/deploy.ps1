<#
  .SYNOPSIS
  Deploys Azure services with the Azure CLI tool

  .DESCRIPTION
  The deploy.ps1 script deploys Azure service using the CLI tool to a resource group in the relevant environment.

  .PARAMETER environmentType
  Specifies the environment type. Staging (DevTest) or production

  .PARAMETER environmentName
   Specifies the environment name. E.g. Dev, Test etc.

   .PARAMETER location
   Specifies the location where the services are deployed. Default is West Europe

  .PARAMETER namingConfig
   Specifies the configuration element used to build the resource names for the resource group and the services

  .INPUTS
  None. You cannot pipe objects to deploy.ps1.

  .OUTPUTS
  None. Udeploy.ps1 does not generate any output.

  .EXAMPLE
  PS> .\deploy.ps1 -environmentType DevTest -environmentName Dev -namingConfig [PSCustomObject]@{companyAbbreviation = "xxx" systemName = "xxx" systemAbbreviation  = "xxx" serviceName = "xxx" serviceAbbreviation = "xxx"}
#>
param (
  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [ValidateSet('DevTest', 'Production')]
  [string]
  $environmentType = "DevTest",

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $environmentName,

  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string]
  $location = "westeurope",

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [PSCustomObject] $namingConfig = @(
    companyAbbreviation = 'xxx'
    systemName = 'xxx'
    systemAbbreviation = 'xxx'
    serviceName = 'xxx'
    serviceAbbreviation = 'xxx'
  )
)

#############################################################################################
# Configure names and options
#############################################################################################
Write-Host "Initialize deployment" -ForegroundColor DarkGreen

# import utility functions
. "$PSScriptRoot\deploy.utilities\deploy.utilities.ps1"
. "$PSScriptRoot\deploy.naming\deploy.naming.ps1"

# Install required extensions
Write-Host "  Installing required extensions" -ForegroundColor DarkYellow
$output = az extension add `
  --name application-insights `
  --yes

Throw-WhenError -output $output

$output = az extension add `
  --name storage-preview `
  --yes

Throw-WhenError -output $output

$output = az extension add `
  --name azure-iot `
  --yes

Throw-WhenError -output $output

# Resource tags
$resourceTags = @(
  "Owner=Auto Deployed",
  "System=$systemName",
  "Environment=$environmentName",
  "Service=$serviceName",
  "Source=https://repo_url"
)

# Set global variables
$global:EnvironmentType = $environmentType
$global:EnvironmentName = $environmentName
$global:Location = $location
$global:NamingConfig = $namingConfig
$global:ResourceTags = $resourceTags

#############################################################################################
# Resource naming section
#############################################################################################

# Environment Resource Names
$envResourceGroupName   = Get-ResourceGroupName -systemName $namingConfig.systemName -environmentName $environmentName
$envResourceName        = Get-ResourceName -companyAbbreviation $namingConfig.companyAbbreviation -systemAbbreviation $namingConfig.systemAbbreviation -environmentName $environmentName

# Resource Names
$resourceGroupName      = Get-ResourceGroupName -serviceName $namingConfig.serviceName -systemName $namingConfig.systemName -environmentName $environmentName
$resourceName           = Get-ResourceName -serviceAbbreviation $namingConfig.serviceAbbreviation -companyAbbreviation $namingConfig.companyAbbreviation -systemAbbreviation $namingConfig.systemAbbreviation -environmentName $environmentName

# Write setup

Write-Host "**********************************************************************" -ForegroundColor White
Write-Host "* Environment name                 : $environmentName" -ForegroundColor White
Write-Host "* Env. resource group name         : $envResourceGroupName" -ForegroundColor White
Write-Host "* Resource group name              : $resourceGroupName" -ForegroundColor White
Write-Host "**********************************************************************" -ForegroundColor White

#############################################################################################
# Provision resource group
#############################################################################################
Write-Host "Provision resource group" -ForegroundColor DarkGreen

Write-Host "  Creating resource group" -ForegroundColor DarkYellow
$output = az group create `
  --name $resourceGroupName `
  --location $location `
  --tags $resourceTags

Throw-WhenError -output $output

#############################################################################################
# Provision Azure Container Registry
#############################################################################################
& "$PSScriptRoot\..\acr\deploy.ps1"