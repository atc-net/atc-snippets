###########################################################################
#
# Use this script to test locally
#
###########################################################################
param (
  [ValidateNotNullOrEmpty()]
  [string]
  $subscriptionId = "d6db0093-ba02-4db3-b89e-d44aa5522ae7"
)
Write-Host "Initialize local deployment" -ForegroundColor Blue

az login --allow-no-subscriptions
az account set --subscription $subscriptionId

$environmentType = "DevTest"
$environmentName = "Dev"
$namingConfig = [PSCustomObject]@{
  companyAbbreviation = "xxx"
  systemName          = "xxx"
  systemAbbreviation  = "xxx"
  serviceName         = "xxx"
  serviceAbbreviation = "xxx"
}

& "$PSScriptRoot\deploy.ps1" -environmentType $environmentType -environmentName $environmentName -namingConfig $namingConfig

