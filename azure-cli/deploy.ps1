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
& "$PSScriptRoot\deploy.services.ps1" -environmentConfig $environmentConfig -namingConfig $namingConfig -resourceTags $resourceTags

if ($?) {
  Write-Host "Deployment successful" -ForegroundColor Green
}
else {
  Write-Host "Deployment failed!" -ForegroundColor Red
}