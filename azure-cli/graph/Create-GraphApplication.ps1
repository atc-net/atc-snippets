# Graph equivalent of az ad app create
function Create-GraphApplication {

  param (
    [Parameter(Mandatory = $true)]
    [string]
    $displayName,
    [Parameter(Mandatory = $false)]
    [string]
    $identifierUri
  )
  if ($null -eq $identifierUri) {
    $app = Invoke-GraphRestRequest -method "post" -url "applications" -body @{displayName = $displayName }
  }
  else {
    $app = Invoke-GraphRestRequest -method "post" -url "applications" -body @{displayName = $displayName; identifierUris = @($identifierUri) }
  }

  return $app
}
