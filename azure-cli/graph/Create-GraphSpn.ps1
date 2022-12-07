function Create-GraphSpn {
  param (
    [Parameter(Mandatory = $true)]
    [string]
    $appId
  )

  $app = Invoke-GraphRestRequest -method "post" -url "servicePrincipals" -body @{appId = $appId }

  return $app
}
