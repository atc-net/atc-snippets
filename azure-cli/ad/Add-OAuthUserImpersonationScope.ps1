function Add-OAuthUserImpersonationScope {
  param(
    [Parameter(Mandatory = $true)]
    [string]
    $SpnId
  )

  # import utility functions
  . "$PSScriptRoot\..\utilities\deploy.utilities.ps1"

  $existingManifest = az rest `
    --method GET `
    --url "https://graph.microsoft.com/v1.0/applications/$SpnId" `
    --headers "Content-Type=application/json" `
  | ConvertFrom-Json

  Throw-WhenError -output $existingManifest

  Write-Host "  Adding 'user_impersonation' scope to App Registration" -ForegroundColor DarkYellow -NoNewline

  $existingPermissionScopes = $existingManifest.api.oauth2PermissionScopes
  $existingScope = $existingPermissionScopes | Where-Object { $_.value -eq "user_impersonation" }

  if ($null -eq $existingScope) {
    $newScope = @{
      adminConsentDescription = "Allow the application to access $($existingManifest.displayName) on behalf of the signed-in user."
      adminConsentDisplayName = "Access $($existingManifest.displayName)"
      id                      = [System.guid]::NewGuid().toString()
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
    }

    $output = az rest `
      --method PATCH `
      --url "https://graph.microsoft.com/v1.0/applications/$SpnId" `
      --headers "Content-Type=application/json" `
      --body (ConvertTo-RequestJson $body)

    Throw-WhenError -output $output

    Write-Host " -> 'user_impersonation' scope added" -ForegroundColor Cyan
  }
  else {
    Write-Host " -> App registration already has 'user_impersonation' scope" -ForegroundColor Cyan
  }
}