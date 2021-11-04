function Get-NewPassword {
  $guid1 = [System.Guid]::NewGuid().ToString().Substring(0, 8)
  $guid2 = [System.Guid]::NewGuid().ToString().ToUpper().Substring(0, 8)
  return $guid1 + $guid2
}