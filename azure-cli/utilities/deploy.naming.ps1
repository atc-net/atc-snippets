class EnvironmentConfig {
  [ValidateNotNullOrEmpty()]
  [string]
  $EnvironmentName

  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [ValidateSet('DevTest', 'Production')]
  [string]
  $EnvironmentType = "DevTest"

  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string]
  $Location = "westeurope"
}

class NamingConfig {
  [ValidateNotNullOrEmpty()][string]$CompanyAbbreviation
  [ValidateNotNullOrEmpty()][string]$SystemName
  [ValidateNotNullOrEmpty()][string]$SystemAbbreviation
  [ValidateNotNullOrEmpty()][string]$ServiceName
  [ValidateNotNullOrEmpty()][string]$ServiceAbbreviation
}

function Get-ResourceGroupName {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $systemName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $environmentName,

    [Parameter(Mandatory = $false)]
    [string]
    $serviceName = ""
  )

  if ($serviceName.Length -gt 0) {
    return $systemName + "-" + $environmentName.ToUpper() + "-" + $serviceName
  }

  return $systemName + "-" + $environmentName.ToUpper()
}

function Get-ResourceName {
  param (
    [Parameter(Mandatory = $true)]
    [EnvironmentConfig] $environmentConfig,

    [Parameter(Mandatory = $true)]
    [NamingConfig] $namingConfig,

    [Parameter(Mandatory = $false)]
    [bool]
    $environmentName = $false,

    [Parameter(Mandatory = $false)]
    [string]
    $suffix = ""
  )

  return $namingConfig.CompanyAbbreviation.ToLower() + $namingConfig.SystemAbbreviation.ToLower() + $environmentConfig.EnvironmentName.ToLower() `
    + $(if (-not $environmentName) { $namingConfig.ServiceAbbreviation.ToLower() }) + $suffix.ToLower()
}

function Get-AppIdentityUri {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('api', 'spn')]
    [string]
    $type,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $companyHostName,

    [Parameter(Mandatory = $true)]
    [EnvironmentConfig] $environmentConfig,

    [Parameter(Mandatory = $true)]
    [NamingConfig] $namingConfig,

    [Parameter(Mandatory = $false)]
    [string]
    $serviceInstance = ""
  )

  if ($serviceInstance.Length -gt 0) {
    $serviceInstance = "/" + $serviceInstance.ToLower()
  }

  return $type + "://" + $namingConfig.SystemAbbreviation.ToLower() + "." + $companyHostName.ToLower() + "/" `
    + $environmentConfig.EnvironmentName.ToLower() + "/" + $namingConfig.ServiceAbbreviation.ToLower() + $serviceInstance
}

function Get-AppIdentityDisplayName {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('api', 'spn')]
    [string]
    $type,

    [Parameter(Mandatory = $true)]
    [EnvironmentConfig] $environmentConfig,

    [Parameter(Mandatory = $true)]
    [NamingConfig] $namingConfig,

    [Parameter(Mandatory = $false)]
    [string]
    $serviceInstance = ""
  )

  if ($serviceInstance.Length -gt 0) {
    $serviceInstance = "-" + $serviceInstance.ToLower()
  }

  return $namingConfig.SystemName + "-" + $environmentConfig.EnvironmentName + "-" + $namingConfig.ServiceName + $serviceInstance + " (" + $type.ToUpper() + ")"
}

function Get-SpnClientIdName {
  param (
    [Parameter(Mandatory = $true)]
    [EnvironmentConfig] $environmentConfig,

    [Parameter(Mandatory = $true)]
    [NamingConfig] $namingConfig,

    [Parameter(Mandatory = $false)]
    [string]
    $serviceInstance = ""
  )

  if ($serviceInstance.Length -gt 0) {
    $serviceInstance = "-" + $serviceInstance.ToLower()
  }

  return $namingConfig.SystemAbbreviation.ToLower() + "-" + $environmentConfig.EnvironmentName.ToLower() `
    + "-" + $namingConfig.ServiceAbbreviation.ToLower() + $serviceInstance + "-clientid"
}

function Get-SpnObjectIdName {
  param (
    [Parameter(Mandatory = $true)]
    [EnvironmentConfig] $environmentConfig,

    [Parameter(Mandatory = $true)]
    [NamingConfig] $namingConfig,

    [Parameter(Mandatory = $false)]
    [string]
    $serviceInstance = ""
  )

  if ($serviceInstance.Length -gt 0) {
    $serviceInstance = "-" + $serviceInstance.ToLower()
  }

  return $namingConfig.SystemAbbreviation.ToLower() + "-" + $environmentConfig.EnvironmentName.ToLower()  `
    + "-" + $namingConfig.ServiceAbbreviation.ToLower() + $serviceInstance + "-objectid"
}

function Get-SpnClientSecretName {
  param (
    [Parameter(Mandatory = $true)]
    [EnvironmentConfig] $environmentConfig,

    [Parameter(Mandatory = $true)]
    [NamingConfig] $namingConfig,

    [Parameter(Mandatory = $false)]
    [string]
    $serviceInstance = ""
  )

  if ($serviceInstance.Length -gt 0) {
    $serviceInstance = "-" + $serviceInstance.ToLower()
  }

  return $namingConfig.SystemAbbreviation.ToLower() + "-" + $environmentConfig.EnvironmentName.ToLower() `
    + "-" + $namingConfig.ServiceAbbreviation.ToLower() + $serviceInstance + "-secret"
}