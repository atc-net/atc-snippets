function Sync-AppSettings {
  [CmdletBinding(DefaultParameterSetName = "WebApp")]
  param (
    [Parameter(Mandatory = $true, ParameterSetName = "WebApp")]
    [Parameter(Mandatory = $true, ParameterSetName = "FunctionApp")]
    [ValidateNotNullOrEmpty()]
    [Alias("Name")]
    [string]
    $AppName,

    [Parameter(Mandatory = $true, ParameterSetName = "WebApp")]
    [Parameter(Mandatory = $true, ParameterSetName = "FunctionApp")]
    [ValidateNotNullOrEmpty()]
    [hashtable]
    $AppSettings,

    [Parameter(Mandatory = $true, ParameterSetName = "WebApp")]
    [Parameter(Mandatory = $true, ParameterSetName = "FunctionApp")]
    [ValidateNotNullOrEmpty()]
    [string]
    $ResourceGroupName,

    [Parameter(ParameterSetName = "WebApp")]
    [switch]
    $WebApp,

    [Parameter(ParameterSetName = "FunctionApp")]
    [switch]
    $FunctionApp
  )

  begin {
    # Get the resource type
    if (($WebApp -and $FunctionApp) -or
       (-not $WebApp -and -not $FunctionApp)) {
      throw "This function needs to invoked with either WebApp or FunctionApp switch parameter"
    }
    elseif ($WebApp) {
      $type = "webapp"
    }
    elseif ($FunctionApp) {
      $type = "functionapp"
    }
  }
  process {
    Write-Host "  Verifying AppSettings" -ForegroundColor DarkYellow -NoNewline
    $output = az $type config appsettings list `
      --resource-group $resourceGroupName `
      --name $AppName `
      --query "[] .{Key: name, Value: value}"

    Throw-WhenError -output $output

    $existingAppSettings = $output | ConvertFrom-Json -AsHashtable

    $addOrUpdateAppSettings = @{} # This is a hashtable
    $deleteAppSettings = [System.Collections.Generic.List[string]]::new()
    $unchangedAppSettings = [System.Collections.Generic.HashSet[string]]::new()

    # Compare the live appsettings with our local appsettings.
    foreach ($keyValuePair in $existingAppSettings) {
      if (-not $AppSettings.Contains($keyValuePair.Key)) {
        # The live appsetting does not exist in our local appsettings.
        # Add it to the deletion list.
        if ($keyValuePair.Key -ne "MACHINEKEY_DecryptionKey") {
          $deleteAppSettings.Add($keyValuePair.Key)
        }
      }
      else {
        $newValue = $AppSettings[$keyValuePair.Key]
        $oldValue = $keyValuePair.Value

        if ($oldValue -ne $newValue) {
          # The live appsetting value does not match our local value.
          # Add it to the update list.
          $addOrUpdateAppSettings.Add($keyValuePair.Key, $newValue)
        }
        else {
          # The live appsetting is equal to our local value.
          # Add it to unchanged list.
          #
          # Hashset.Add() returns a boolean representation the success of the operation.
          # If we pipe the result to `$null`, we avoid printing the bool in our terminal.
          $unchangedAppSettings.Add($keyValuePair.Key) > $null
        }
      }
    }

    # Finally we want to detect if there is new local appsettings not present in the live dataset.
    foreach ($keyValuePair in $AppSettings.GetEnumerator()) {
      if (-not ($unchangedAppSettings.Contains($keyValuePair.Key) -or
          $addOrUpdateAppSettings.Contains($keyValuePair.Key))) {
        # The appsetting name is not present in the update or unchanged list.
        # This means it's a brand new appsetting, so we add it to the update list.
        $addOrUpdateAppSettings.Add($keyValuePair.Key, $keyValuePair.Value)
      }
    }

    if ($addOrUpdateAppSettings.Count -gt 0 -or $deleteAppSettings.Count -gt 0) {
      Write-Host " -> AppSettings changes detected" -ForegroundColor Cyan

      if ($addOrUpdateAppSettings.Count -gt 0) {
        $newAppSettings = $addOrUpdateAppSettings.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }

        Write-Host "    Adding or updating $($addOrUpdateAppSettings.Count) AppSettings ($newAppSettings)"
        $output = az $type config appsettings set `
          --name $AppName `
          --resource-group $ResourceGroupName `
          --settings $newAppSettings

        Throw-WhenError -output $output
      }

      if ($deleteAppSettings.Count -gt 0) {
        Write-Host "    Deleting $($deleteAppSettings.Count) AppSettings ($deleteAppSettings)"
        $output = az $type config appsettings delete `
          --name $AppName `
          --resource-group $ResourceGroupName `
          --setting-names $deleteAppSettings

        Throw-WhenError -output $output
      }
    }
    else {
      Write-Host " -> AppSettings are correct." -ForegroundColor Cyan
    }
  }
}