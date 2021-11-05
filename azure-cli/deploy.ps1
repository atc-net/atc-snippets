<#
  .SYNOPSIS
  Main script responsible for deploying an Azure environment using IaC.

  .DESCRIPTION
  The deploy.ps1 script calls the following two scripts;

    deploy.initial.ps1 - deploys Azure resource groups and key vaults for an application with an environment resource group and a service recource group
    deploy.services.ps1 - deploys any needed Azure services into the resource groups

  .PARAMETER environmentConfig
  Specifies the environment configuration

  .PARAMETER namingConfig
  Specifies the configuration element used to build the resource names for the resource group and the services

  .PARAMETER resourceTags
  Specifies the tag elements that will be used to tag the deployed services

  .INPUTS
  None. You cannot pipe objects to deploy.ps1.

  .OUTPUTS
  None. deploy.ps1 does not generate any output.
#>

param (
  [ValidateNotNullOrEmpty()]
  [ValidateSet('DevTest', 'Production')]
  [string]
  $environmentType = "DevTest",

  [ValidateNotNullOrEmpty()]
  [string]
  $environmentName = "Dev"
)

Write-Host "Initialize deployment" -ForegroundColor DarkGreen

# import utility functions
. "$PSScriptRoot\utilities\deploy.naming.ps1"

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
  "System=$($namingConfig.SystemName)",
  "Environment=$($environmentConfig.EnvironmentName)",
  "Service=$($namingConfig.ServiceName)",
  "Source=https://repo_url"
)

& "$PSScriptRoot\deploy.initial.ps1" -environmentConfig $environmentConfig -namingConfig $namingConfig -resourceTags $resourceTags
& "$PSScriptRoot\deploy.services.ps1" -environmentConfig $environmentConfig -namingConfig $namingConfig -resourceTags $resourceTags -subscriptionId $subscriptionId -sendGridApiKey $sendGridApiKey

if ($?) {
  Write-Host "Deployment successful" -ForegroundColor Green
}
else {
  Write-Host "Deployment failed!" -ForegroundColor Red
}