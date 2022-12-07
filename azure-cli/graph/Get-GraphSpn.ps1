function Get-GraphSpn {

  param (
    [Parameter(Mandatory = $true)]
    [string]
    $queryDisplayName
  )

  $apps = (Invoke-GraphRestRequest -url "servicePrincipals?`$filter=displayName in ('$($queryDisplayName)')&`$count=true").value

    

  if (($apps.displayName | Format-List).length -ne 1) {
    if ( [string]::IsNullOrEmpty($apps)) {
      return $null
    }
    throw "Either none or more than 1 servicePrincipals was found."
  } 

  return $apps
}
