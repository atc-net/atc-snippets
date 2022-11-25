function Remove-GraphAppPassword {
  param (
    [Parameter(Mandatory = $true)]
    [string]
    $keyId,

    [Parameter(Mandatory = $true)]
    [string]
    $appId
  )


  Invoke-GraphRestRequest `
    -method post `
    -url applications/$appId/removePassword `
    -body @{
    keyId = $keyId
  }
}
