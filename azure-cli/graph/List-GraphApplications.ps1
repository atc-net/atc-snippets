function List-GraphApplications {

  param (
    [Parameter(Mandatory = $true)]
    [string]
    $queryDisplayName
  )

  $apps = (Invoke-GraphRestRequest -url "applications").value

  $apps = $apps | Where-Object { $_.displayName -eq $queryDisplayName }

  return $apps
}
