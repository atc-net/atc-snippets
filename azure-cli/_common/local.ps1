###########################################################################
#
# Use this script to test locally
#
###########################################################################
Write-Host "Initialize local deployment" -ForegroundColor Blue
$subscriptionId = "00000000-0000-0000-0000-000000000000"
$environmentType = "DevTest"
$environmentName = "Dev"

& '.\deploy.ps1' `
    -environmentType $environmentType `
    -environmentName $environmentName `
    -subscriptionId $subscriptionId