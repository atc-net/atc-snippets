function Set-KeyVaultSecretPermissions {
  param (
    [Parameter(Mandatory = $true)]
    [Alias("Name")]
    [string]
    $KeyVaultName,
    
    [Parameter(Mandatory = $true)]
    [string]
    $ObjectId,

    [Parameter(Mandatory = $true)]
    [ValidateSet("all", "backup", "delete", "get", "list", "purge", "recover", "restore", "set")]
    [string[]]
    $SecretPermissions,

    [Parameter(Mandatory = $true)]
    [string]
    $ResourceGroupName
  )

  Write-Host "  Verifying secret permissions '$SecretPermissions' on Key Vault '$KeyVaultName' for Object ID '$ObjectId'" -ForegroundColor DarkYellow -NoNewline

  $output = az keyvault list `
    --resource-group $ResourceGroupName `
    --query "[?name=='$KeyVaultName']|[0].properties.accessPolicies[?objectId=='$ObjectId']|[0].permissions.secrets"

  # Create a boolean that determines if we should invoke the `az keyvault set-policy` command.
  # If the $output variable is null, it means that there are no pre-existing policies configured and thus we should always invoke the command.
  $invokeSetKeyVaultPolicy = $null -eq $output

  if (-not $invokeSetKeyVaultPolicy) {
    # If $invokeSetKeyVaultPolicy is false, we know that we got a match and a valid JSON response from the query above.
    $existingPermissions = $output | ConvertFrom-Json

    # Use LINQ to determine if all the permissions in our $SecretPermissions parameter is already present on the key vault.
    $invokeSetKeyVaultPolicy = ![Linq.Enumerable]::All($SecretPermissions, [Func[string, bool]] { param($x) $existingPermissions.Contains($x) })
  }

  if ($invokeSetKeyVaultPolicy) {
    Write-Host "  -> Permissions are not configured." -ForegroundColor Cyan
    Write-Host "  Granting '$SecretPermissions' secret permissions to Key Vault '$KeyVaultName'" -ForegroundColor DarkYellow
    $output = az keyvault set-policy `
      --object-id $ObjectId `
      --secret-permissions $SecretPermissions `
      --name $KeyVaultName `
      --resource-group $ResourceGroupName

    Throw-WhenError -output $output
  }
  else {
    Write-Host " -> Permissions are already configured." -ForegroundColor Cyan
  }
}