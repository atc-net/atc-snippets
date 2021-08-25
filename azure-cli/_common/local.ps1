###########################################################################
#
# Use this script to test locally
#
###########################################################################
param (
  [ValidateNotNullOrEmpty()]
  [string]
  $subscriptionId = "00000000-0000-0000-0000-000000000000"
)

Write-Host "Initialize local deployment" -ForegroundColor Blue

# import utility functions
. "$PSScriptRoot\utilities\deploy.naming.ps1"
. "$PSScriptRoot\..\account\set_loginaccount.ps1"

Set-LoginAccount -subscriptionId $subscriptionId

$environmentConfig = [EnvironmentConfig]::new()
$environmentConfig.EnvironmentName = "Dev"
$environmentConfig.EnvironmentType = "DevTest"
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
& "$PSScriptRoot\deploy.ps1" -tenantId $tenantId -environmentConfig $environmentConfig -namingConfig $namingConfig -resourceTags $resourceTags

