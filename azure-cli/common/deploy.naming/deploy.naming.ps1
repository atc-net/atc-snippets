function Get-ResourceGroupName {
  param (
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $systemName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $environmentName,

    [Parameter(Mandatory=$false)]
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
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $companyAbbreviation,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $systemAbbreviation,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $environmentName,

    [Parameter(Mandatory=$false)]
    [string]
    $serviceAbbreviation = "",

    [Parameter(Mandatory=$false)]
    [string]
    $suffix = ""
  )

  return $companyAbbreviation.ToLower() + $systemAbbreviation.ToLower() + $environmentName.ToLower() + $serviceAbbreviation.ToLower() + $suffix.ToLower()
}

function Get-AppIdentityUri {
  param (
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('api', 'spn')]
    [string]
    $type,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $companyHostName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $systemAbbreviation,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $environmentName,

    [Parameter(Mandatory=$true)]
    [string]
    $serviceAbbreviation,

    [Parameter(Mandatory=$false)]
    [string]
    $serviceInstance = ""
  )

  if ($serviceInstance.Length -gt 0) {
    $serviceInstance = "/" + $serviceInstance.ToLower()
  }

  return $type + "://" + $systemAbbreviation.ToLower() + "." + $companyHostName.ToLower() + "/" + $environmentName.ToLower() + "/" + $serviceAbbreviation.ToLower() + $serviceInstance
}

function Get-AppIdentityDisplayName {
  param (
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('api', 'spn')]
    [string]
    $type,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $systemName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $environmentName,

    [Parameter(Mandatory=$true)]
    [string]
    $serviceName,

    [Parameter(Mandatory=$false)]
    [string]
    $serviceInstance = ""
  )

  if ($serviceInstance.Length -gt 0) {
    $serviceInstance = "-" + $serviceInstance.ToLower()
  }

  return $systemName + "-" + $environmentName + "-" + $serviceName + $serviceInstance + " (" + $type.ToUpper() + ")"
}

function Get-SpnClientIdName {
  param (
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $environmentName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $systemAbbreviation,

    [Parameter(Mandatory=$true)]
    [string]
    $serviceAbbreviation,

    [Parameter(Mandatory=$false)]
    [string]
    $serviceInstance = ""
  )

  if ($serviceInstance.Length -gt 0) {
    $serviceInstance = "-" + $serviceInstance.ToLower()
  }

  return $systemAbbreviation.ToLower() + "-" + $environmentName.ToLower() + "-" + $serviceAbbreviation.ToLower() + $serviceInstance + "-clientid"
}

function Get-SpnClientSecretName {
  param (
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $environmentName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $systemAbbreviation,

    [Parameter(Mandatory=$true)]
    [string]
    $serviceAbbreviation,

    [Parameter(Mandatory=$false)]
    [string]
    $serviceInstance = ""
  )

  if ($serviceInstance.Length -gt 0) {
    $serviceInstance = "-" + $serviceInstance.ToLower()
  }

  return $systemAbbreviation.ToLower() + "-" + $environmentName.ToLower() + "-" + $serviceAbbreviation.ToLower() + $serviceInstance + "-secret"
}