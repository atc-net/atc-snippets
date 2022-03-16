function ConvertFrom-LocationDisplayName {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [Alias("Input")]
    [string]
    $LocationDisplayName
  )

  process {
      $LocationDisplayName.ToLower() -replace '[^a-z0-9\\]'
  }
}