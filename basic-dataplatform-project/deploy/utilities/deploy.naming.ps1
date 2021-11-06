class EnvironmentConfig {

  [ValidateNotNullOrEmpty()][string]$EnvironmentName
  [ValidateNotNullOrEmpty()][string]$DevelopmentEnvironment
  [ValidateNotNullOrEmpty()][string]$ProductEnvironment

  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string]
  $Location = "westeurope"
}

class NamingConfig
{
    [ValidateNotNullOrEmpty()][string]$ResourceGroupPrefix
    [ValidateNotNullOrEmpty()][string]$ResourceGroupSuffix
    [ValidateNotNullOrEmpty()][string]$SystemName
    [ValidateNotNullOrEmpty()][string]$SystemAbbreviation  
}

function Get-ResourceName {
  param (
    [Parameter(Mandatory = $true)]
    [EnvironmentConfig] $environmentConfig,

    [Parameter(Mandatory = $true)]
    [NamingConfig] $namingConfig,

    [Parameter(Mandatory = $false)]
    [string]
    $suffix
  )

  return "$($namingConfig.SystemAbbreviation.ToLower())$($environmentConfig.DevelopmentEnvironment.ToLower())$($environmentConfig.ProductEnvironment.ToLower())$($suffix)"
}

function Get-KeyVaultName {
  param (
    [Parameter(Mandatory = $true)]
    [EnvironmentConfig] $environmentConfig,

    [Parameter(Mandatory = $true)]
    [NamingConfig] $namingConfig
  )

  return "$($namingConfig.SystemAbbreviation.ToLower())-$($environmentConfig.DevelopmentEnvironment.ToLower())-$($environmentConfig.ProductEnvironment.ToLower())-kv"
}

function Get-ResourceGroupName {
  param (
    [Parameter(Mandatory = $true)]
    [EnvironmentConfig] $environmentConfig,

    [Parameter(Mandatory = $true)]
    [NamingConfig] $namingConfig
  )

  return "$($namingConfig.ResourceGroupPrefix)-$($namingConfig.SystemAbbreviation)-$($environmentConfig.DevelopmentEnvironment.ToLower())-$($namingConfig.ResourceGroupSuffix)"
}