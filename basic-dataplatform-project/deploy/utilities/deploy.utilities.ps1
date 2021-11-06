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