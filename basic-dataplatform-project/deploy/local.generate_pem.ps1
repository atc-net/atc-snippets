param (
  [ValidateNotNullOrEmpty()]
  [string]
  $environmentName = "Development",

  [ValidateNotNullOrEmpty()]
  [string]
  $developmentEnvironment,

  [ValidateNotNullOrEmpty()]
  [string]
  $productEnvironment,

  [ValidateNotNullOrEmpty()]
  [string]
  $subscriptionId,

  [ValidateNotNullOrEmpty()]
  [string]
  $tenantId,

  [ValidateNotNullOrEmpty()]
  [string]
  $pemFilename
)

# Log in as your regular ISS user to get access to keyvault
az login --allow-no-subscriptions --tenant $tenantId
az account set --subscription $subscriptionId

# import utility functions
. "$PSScriptRoot\utilities\deploy.utilities.ps1"
. "$PSScriptRoot\utilities\deploy.naming.ps1"
. "$PSScriptRoot\keyvault\get_KeyVaultSecret.ps1"

# Create environment and naming config objects for keyvault utility functions
$environmentConfig = [EnvironmentConfig]::new()
$environmentConfig.DevelopmentEnvironment = $developmentEnvironment
$environmentConfig.ProductEnvironment = $productEnvironment

$namingConfig = [NamingConfig]::new()
$namingConfig.SystemAbbreviation = "bigiot"

$keyVaultName = Get-KeyVaultName -environmentConfig $environmentConfig -namingConfig $namingConfig

# Get base64 encrypted PKCS #12 certificate and its password
$certificateAsBase64 = Get-KeyVaultSecret -keyVaultName $keyVaultName -secretName "bigiotIACProvisioningAppRegPkcs12B64"
Throw-WhenError -output $certificateAsBase64

$certificatePassword = Get-KeyVaultSecret -keyVaultName $keyVaultName -secretName "bigiotIACProvisioningAppRegPkcs12PW"
Throw-WhenError -output $certificatePassword

Write-Host "  Converting secrets to PEM" -ForegroundColor DarkYellow
$pfxCertificate = [Convert]::FromBase64String($certificateAsBase64)

# Because PowerShell doesn't support piping of binary data, we write the PKCS #12 certificate to a file so we can pass it to openssl
$pfxFile = "$PSScriptRoot/$pemFilename" -replace ".pem", ".pfx"
[IO.File]::WriteAllBytes($pfxFile, $pfxCertificate)

# Generate pem with OpenSSL CLI
openssl pkcs12 -in $pfxFile -out "$pemFilename" -passin pass:$certificatePassword -nodes

# Delete the PKCS #12 certificate file
Remove-Item $pfxFile
