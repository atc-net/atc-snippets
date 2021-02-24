param (
  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [ValidateSet('DevTest', 'Production')]
  [string]
  $environmentType = "DevTest",

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $environmentName
)

#############################################################################################
# Configure names and options
#############################################################################################
Write-Host "Initialize deployment" -ForegroundColor DarkGreen

# import utility functions
. ".\deploy.utilities.ps1"
. ".\deploy.naming.ps1"

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

# Naming rule configurations
$companyAbbreviation = "xxx"
$systemName          = "xxx"
$systemAbbreviation  = "xxx"
$serviceName         = "xxx"
$serviceAbbreviation = "xxx"

# Location
$location = "westeurope"

# Resource tags
$resourceTags = @(
  "Owner=Auto Deployed",
  "System=$systemName",
  "Environment=$environmentName",
  "Service=$serviceName",
  "Source=https://repo_url"
)

#############################################################################################
# Resource naming section
#############################################################################################

# Environment Resource Names
$envResourceGroupName   = Get-ResourceGroupName -systemName $systemName -environmentName $environmentName
$envResourceName        = Get-ResourceName -companyAbbreviation $companyAbbreviation -systemAbbreviation $systemAbbreviation -environmentName $environmentName

# Resource Names
$resourceGroupName      = Get-ResourceGroupName -serviceName $serviceName -systemName $systemName -environmentName $environmentName
$resourceName           = Get-ResourceName -serviceAbbreviation $serviceAbbreviation -companyAbbreviation $companyAbbreviation -systemAbbreviation $systemAbbreviation -environmentName $environmentName

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