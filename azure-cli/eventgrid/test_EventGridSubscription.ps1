function Test-EventGridSubscription {
  param(
    [Parameter(Mandatory=$true)]
    [string]
    $name,

    [Parameter(Mandatory=$true)]
    [string]
    $sourceResourceId,

    [Parameter(Mandatory=$false)]
    [array]
    $includedEventTypes = @(),

    [Parameter(Mandatory=$false)]
    [string]
    $advancedFilter = $null
  )

  $query = "[?name=='$name'"
  if ($advancedFilter.Length -gt 0) {
    $query = "$query && filter.advancedFilters[?values[?contains(@, '$advancedFilter')]]"
  }
  foreach ($eventType in $includedEventTypes) {
    $query = "$query && filter.includedEventTypes[?contains(@, '$eventType')]"
  }
  $query = "$query] | [0]"

  $output = az eventgrid event-subscription list `
    --source-resource-id $sourceResourceId `
    --query $query `
    2> $null

  return $output.Length -gt 0
}