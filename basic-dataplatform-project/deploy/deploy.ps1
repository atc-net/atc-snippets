###########################################################################
#
# Use this script to deploy
#
###########################################################################
param (
  [ValidateNotNullOrEmpty()]
  [string]
  $environmentName = "Development",

  [ValidateNotNullOrEmpty()]
  [string]
  $developmentEnvironment,

  [ValidateNotNullOrEmpty()]
  [string]
  $productEnvironment,

  [ValidateNotNullOrEmpty()]
  [string]
  $subscriptionId,

  [ValidateNotNullOrEmpty()]
  [string]
  $clientId
)

Write-Host "Initialize deployment" -ForegroundColor DarkGreen

# import utility functions
. "$PSScriptRoot\utilities\deploy.naming.ps1"

$environmentConfig = [EnvironmentConfig]::new()
$environmentConfig.EnvironmentName = $environmentName
$environmentConfig.DevelopmentEnvironment = $developmentEnvironment
$environmentConfig.ProductEnvironment = $productEnvironment
$environmentConfig.Location = "westeurope"

$namingConfig = [NamingConfig]::new()
$namingConfig.ResourceGroupPrefix = ""
$namingConfig.ResourceGroupSuffix = ""
$namingConfig.SystemName = ""
$namingConfig.SystemAbbreviation = ""

$resourceTags = @(
  "EnvironmentName=$($environmentConfig.environmentName)",  
  "Product=$($namingConfig.SystemAbbreviation)",
  "SystemName=$($namingConfig.SystemName)",
  "IssOwner=Anders.Moeldrup@group.issworld.com",
  "Provisioning=Azure CLI"
  "Source=https://dev.azure.com/issworld/IOT%20comfort%20predictability/_git/bigiot-environment"
)

& "$PSScriptRoot\deploy.services.ps1" -tenantId $tenantId -clientId $clientId -environmentConfig $environmentConfig -namingConfig $namingConfig -resourceTags $resourceTags
if ($?) {
  Write-Host "Deployment successful" -ForegroundColor Green
}
else {
  Write-Host "Deployment failed!" -ForegroundColor Red
}