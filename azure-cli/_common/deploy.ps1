###########################################################################
#
# Use this script to deploy
#
###########################################################################
param (
  [ValidateNotNullOrEmpty()]
  [ValidateSet('DevTest', 'Production')]
  [string]
  $environmentType = "DevTest",

  [ValidateNotNullOrEmpty()]
  [string]
  $environmentName = "Dev",

  [ValidateNotNullOrEmpty()]
  [string]
  $subscriptionId
)

Write-Host "Initialize deployment" -ForegroundColor DarkGreen

# import utility functions
. "$PSScriptRoot\utilities\deploy.naming.ps1"
. "$PSScriptRoot\..\account\set_loginaccount.ps1"

Set-LoginAccount -subscriptionId $subscriptionId

$environmentConfig = [EnvironmentConfig]::new()
$environmentConfig.EnvironmentName = $environmentName
$environmentConfig.EnvironmentType = $environmentType
$environmentConfig.Location = "westeurope"

$namingConfig = [NamingConfig]::new()
$namingConfig.CompanyAbbreviation = "xx"
$namingConfig.SystemName = "xx"
$namingConfig.SystemAbbreviation = "xx"
$namingConfig.ServiceName = "xx"
$namingConfig.ServiceAbbreviation = "xx"

$resourceTags = @(
  "Owner=Auto Deployed",
  "System=$($namingConfig.systemName)",
  "Environment=$($namingConfig.environmentName)",
  "Service=$($namingConfig.serviceName)",
  "Source=https://repo_url"
)

& "$PSScriptRoot\deploy.initial.ps1" -environmentConfig $environmentConfig -namingConfig $namingConfig -resourceTags $resourceTags
& "$PSScriptRoot\deploy.services.ps1" -tenantId $tenantId -environmentConfig $environmentConfig -namingConfig $namingConfig -resourceTags $resourceTags -subscriptionId $subscriptionId -sendGridApiKey $sendGridApiKey

Write-Host "Deployment successful" -ForegroundColor Green