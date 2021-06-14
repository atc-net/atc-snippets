# Install required extensions
Write-Host "  Installing required extensions" -ForegroundColor DarkYellow
$output = az extension add `
  --name application-insights `
  --yes

Throw-WhenError -output $output

$output = az extension add `
  --name storage-preview `
  --yes

Throw-WhenError -output $output

$output = az extension add `
  --name azure-iot `
  --yes

Throw-WhenError -output $output

$output = az extension add `
  --name timeseriesinsights `
  --yes

Throw-WhenError -output $output


Write-Host "  Install Azure DevOps extension" -ForegroundColor DarkYellow
az extension add --name azure-devops --yes