###########################################################################
#
# Use this script to test locally
#
###########################################################################
Write-Host "Initialize local deployment" -ForegroundColor Blue

$environmentName = "Development"
$developmentEnvironment = "prdev"
$productEnvironment = "dev"
$subscriptionId = ""
$appId = ""
$tenantId = ""

$pemFile = "bigiot$($developmentEnvironment)$($productEnvironment).pem"
if ((Test-Path -Path $pemFile) -eq $false) {
    Write-Host "  Service Principal PEM file not found, need to generate one ..." -ForegroundColor DarkYellow
    & '.\local.generate_pem.ps1' `
        -developmentEnvironment $developmentEnvironment `
        -productEnvironment $productEnvironment `
        -subscriptionId $subscriptionId `
        -tenantId $tenantId `
        -pemFilename $pemFile
}

az login --service-principal --username $appId --tenant $tenantId --password (Resolve-Path -Relative $pemFile)

& '.\deploy.ps1' `
    -environmentName $environmentName `
    -developmentEnvironment $developmentEnvironment `
    -productEnvironment $productEnvironment `
    -subscriptionId $subscriptionId