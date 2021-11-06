# Install required extensions
Write-Host "  Installing required extensions" -ForegroundColor DarkYellow
$output = az extension add `
  --name databricks `
  --yes

Throw-WhenError -output $output