function Add-GraphAppPassword  {
  param (
    [Parameter(Mandatory = $false)]
    [string]
    $displayName = "spn password",

    [Parameter(Mandatory = $true)]
    [string]
    $appId
  )

  # How to add end and start date:
  # https://docs.microsoft.com/en-us/graph/api/serviceprincipal-addpassword?view=graph-rest-1.0&tabs=http
    

  $app = Invoke-GraphRestRequest `
    -method post `
    -url applications/$appId/addPassword `
    -body @{
    passwordCredential = @{
      displayName = $displayName
      }
  }

  # The most important output property is secretText: $app.secretText
  return $app
}
