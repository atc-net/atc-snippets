function Throw-WhenError {
  param (
    [string]
    $output
  )

  if ($LastExitCode -gt 0)
  {
    Write-Error $output
    throw
  }
}

function ConvertTo-PlainText {
  param (
    [Parameter(Mandatory=$true)]
    [securestring]
    $secret
  )

  return [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret))
}

function ConvertTo-Base64String {
  param (
    [Parameter(ValueFromPipeline, Mandatory=$true)]
    [string]
    $text
  )

  $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
  return [System.Convert]::ToBase64String($bytes)
}