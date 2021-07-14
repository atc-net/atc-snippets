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

$output = az extension add `
  --name log-analytics `
  --yes

Throw-WhenError -output $output

$output = az extension add `
  --name databricks `
  --yes

Throw-WhenError -output $output

# TO-BE-SORTED:
# -------------

# datafactory

# kusto

# scheduled-query

# aks-preview

# mixed-reality

# azure-cli-ml vs. ml?!

# webpubsub

# azure-devops