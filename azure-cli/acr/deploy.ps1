param (
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('DevTest', 'Production')]
    [string]
    $environmentType = $global:EnvironmentType,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $environmentName = $global:EnvironmentName,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $location = $global:Location,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [PSCustomObject] $namingConfig = $global:NamingConfig,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [PSCustomObject] $resourceTags = $global:ResourceTags
)

#############################################################################################
# Resource naming section
#############################################################################################
$resourceGroupName      = Get-ResourceGroupName -serviceName $namingConfig.serviceName -systemName $namingConfig.systemName -environmentName $environmentName
$registryName           = Get-ResourceName -serviceAbbreviation $namingConfig.serviceAbbreviation -companyAbbreviation $namingConfig.companyAbbreviation -systemAbbreviation $namingConfig.systemAbbreviation -environmentName $environmentName -suffix "acr"

#############################################################################################
# Azure Container Registry
#############################################################################################
Write-Host "Provision Azure Container Registry" -ForegroundColor DarkGreen

Write-Host "  Creating Azure Container Registry" -ForegroundColor DarkYellow

$containerRegistryLoginServer = az acr create `
  --resource-group $resourceGroupName `
  --name $registryName `
  --sku Standard `
  --admin-enabled `
  --tags $resourceTags `
  --query loginServer `
  --output tsv

Throw-WhenError -output $containerRegistryLoginServer
