function Get-GraphApplication {

  param (
    [Parameter(Mandatory = $true)]
    [string]
    $queryDisplayName
  )

  $apps = (Invoke-GraphRestRequest -url "applications?`$filter=displayName in ('$($queryDisplayName)')&`$count=true").value

    

  if (($apps.displayName | Format-List).length -ne 1) {
    if ([string]::IsNullOrEmpty($apps)) {
      return $null
    }
    throw "Either none or more than 1 applications was found."
  } 

  return $apps
}
