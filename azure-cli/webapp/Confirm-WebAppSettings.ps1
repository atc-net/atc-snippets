
function Confirm-WebAppSettings {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [Alias("Name", "AppName")]
    [string]
    $WebAppName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [hashtable]
    $AppSettings,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ResourceGroupName
  )

  $output = az webapp config appsettings list `
    --resource-group $resourceGroupName `
    --name $WebAppName `
    --query "[] .{Key: name, Value: value}"

  Throw-WhenError -output $output

  $existingAppSettings = $output | ConvertFrom-Json -AsHashtable

  $existingAppSettingsCount = 0
  # Check if there is any pre-existing settings that have different values than what we expect.
  # If we get a mismatch, return false immediately as we have confirmed a change.
  foreach ($keyValuePair in $existingAppSettings) {
    if ($AppSettings[$keyValuePair.Key] -ne $keyValuePair.Value) {
      return $false
    }
    $existingAppSettingsCount += 1
  }

  # Finally check if there is a mismatch between the count of expected appsettings and the actual appsettings.
  # The loop above only catches mismatches, while this will catch if we have added or removed a setting.
  return $existingAppSettingsCount -eq $AppSettings.Count
}