function Get-SqlConnectionString {
    param (
      [Parameter(Mandatory=$true)]
      [string]
      $userId,

      [Parameter(Mandatory=$true)]
      [string]
      $password,

      [Parameter(Mandatory=$true)]
      [string]
      $database,

      [Parameter(Mandatory=$true)]
      [string]
      $server
    )

    return "Server=tcp:" `
      + $server `
      + ".database.windows.net,1433;Initial Catalog=" `
      + $database `
      + ";Persist Security Info=False;User ID=" `
      + $userId `
      + ";Password=" `
      + $password `
      + ";MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;";
}