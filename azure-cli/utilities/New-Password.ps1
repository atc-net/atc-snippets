function New-Password {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateRange(4, 4096)]
    [Alias("Length")]
    [int]
    $PasswordLength,

    [switch]
    $NoSpecialCharacters
  )

  $upperCaseCharacters = [char]'A'..[char]'Z'
  $lowerCaseCharacters = [char]'a'..[char]'z'
  $numbers = [char]'0'..[char]'9'

  $availableCharacters = $upperCaseCharacters + $lowerCaseCharacters + $numbers

  if (-not $NoSpecialCharacters.IsPresent) {
    # The special characters array will contain ~!@#$%^&*_-+=`|\(){}[]:;"'<>,.?/ as listed in
    # https://learn.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/password-must-meet-complexity-requirements
    $specialCharacters = [char]33..[char]47 + [char]58..[char]64 + [char]91..[char]96 + [char]123..[char]126
    $availableCharacters += $specialCharacters
  }

  # Generate a new random password until we hit one that contains all of the following criteria:
  # a number, a lower-case character, an upper-case character, and a special character (if not disabled).
  $passesComplexityCheck = $false

  do {
    $passwordCharacters = @()

    for ($i = 0; $i -lt $PasswordLength; $i++) {
      $passwordCharacters += $availableCharacters | Get-Random
    }

    $password = -join $passwordCharacters

    $passesComplexityCheck = `
      $password -cmatch "[A-Z\p{Lu}\s]" -and `
      $password -cmatch "[a-z\p{Ll}\s]" -and `
      $password -match "[\d]"

    if ($passesComplexityCheck -and -not $NoSpecialCharacters.IsPresent) {
      $passesComplexityCheck = $password -match "[^\w]|_"
    }
		
  } while (-not $passesComplexityCheck)

  return $password
}