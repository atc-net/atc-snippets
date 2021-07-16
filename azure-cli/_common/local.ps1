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

. "$PSScriptRoot\..\account\set_loginaccount.ps1"

Set-LoginAccount -subscriptionId $subscriptionId

$environmentType = "DevTest"

$namingConfig = [PSCustomObject]@{
  environmentName = "Dev"
  companyAbbreviation = "xxx"
  systemName          = "xxx"
  systemAbbreviation  = "xxx"
  serviceName         = "xxx"
  serviceAbbreviation = "xxx"
}
$resourceTags = @(
  "Owner=Auto Deployed",
  "System=$($namingConfig.systemName)",
  "Environment=$($namingConfig.environmentName)",
  "Service=$($namingConfig.serviceName)",
  "Source=https://repo_url"
)

& "$PSScriptRoot\deploy.initial.ps1" -environmentType $environmentType -namingConfig $namingConfig -resourceTags $resourceTags
& "$PSScriptRoot\deploy.ps1" -tenantId $tenantId -environmentType $environmentType -namingConfig $namingConfig -resourceTags $resourceTags

