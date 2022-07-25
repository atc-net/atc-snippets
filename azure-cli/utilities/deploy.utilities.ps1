function Throw-WhenError {
  param (
    [string]
    $output
  )

  if ($LastExitCode -gt 0) {
    Write-Error $output
    throw
  }
}

function ConvertTo-PlainText {
  param (
    [Parameter(Mandatory = $true)]
    [securestring]
    $secret
  )

  return [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret))
}

function ConvertTo-Base64String {
  param (
    [Parameter(ValueFromPipeline, Mandatory = $true)]
    [string]
    $text
  )

  $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
  return [System.Convert]::ToBase64String($bytes)
}

function ConvertTo-RequestJson {
  param (
    [Parameter(ValueFromPipeline, Mandatory = $true)]
    [object]
    $Object,

    [Parameter(Mandatory = $false)]
    [int]
    $Depth = 4
  )

  return $Object | ConvertTo-Json -Compress -Depth $Depth | ForEach-Object {$_.Replace('"', '\"')}
}