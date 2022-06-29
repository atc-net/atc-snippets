function Add-OAuthUserImpersonationScope(
  [Parameter(Mandatory = $true)]
  [string]
  $spnId
) {

  $existingManifest = az rest `
    --method Get `
    --url https://graph.microsoft.com/v1.0/applications/$spnId `
    --headers "Content-Type=application/json" `
  | ConvertFrom-Json

  Throw-WhenError -output $existingManifest

  $existingPermissionScopes = $existingManifest.api.oauth2PermissionScopes
  $existingScope = $existingPermissionScopes | Where-Object { $_.value -eq "user_impersonation" }

  if ($null -eq $existingScope) {
    $newScope = @{
      adminConsentDescription = "Allow the application to access $($existingManifest.displayName) on behalf of the signed-in user."
      adminConsentDisplayName = "Access $($existingManifest.displayName)"
      id                      = $([System.guid]::NewGuid().toString())
      isEnabled               = $true
      type                    = "User"
      userConsentDescription  = "Allow the application to access $($existingManifest.displayName) on your behalf."
      userConsentDisplayName  = "Access $($existingManifest.displayName)"
      value                   = "user_impersonation"
    }

    $existingPermissionScopes += $newScope

    $body = @{
      api = @{
        oauth2PermissionScopes = $existingPermissionScopes
      }
    } | ConvertTo-Json -Depth 4

    Set-Content ./manifest.json $body

    az rest `
      --method patch `
      --url https://graph.microsoft.com/v1.0/applications/$spnId `
      --headers "Content-Type=application/json" `
      --body `@manifest.json

    Throw-WhenError -output $output
  }
}