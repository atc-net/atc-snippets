function List-GraphSpn {

    param (
      [Parameter(Mandatory=$true)]
      [string]
      $queryDisplayName
    )

    $apps = (Invoke-GraphRestRequest -url "servicePrincipals").value

    if($queryDisplayName){
      return $apps | Where-Object {$_.displayName -eq $queryDisplayName}
    }

    return $apps
}
