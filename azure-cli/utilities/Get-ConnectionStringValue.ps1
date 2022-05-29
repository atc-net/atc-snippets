function Get-ConnectionStringValue {
  param(
    [Parameter(Mandatory = $true)]
    [string]
    $ConnectionString,

    [Parameter(Mandatory = $true)]
    [string]
    $Key
  )

  $connectionStringValues = @{}
  $ConnectionString -Split ";" | ForEach-Object {
    $k, $v = $_ -Split "="
    $connectionStringValues[$k] = $v
  }

  return $connectionStringValues[$Key]
}