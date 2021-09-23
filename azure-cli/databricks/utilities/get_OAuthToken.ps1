function Get-OAuthToken {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $tenantId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $clientId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $clientSecret,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $scope = "2ff814a6-3304-4ab8-85cb-cd0e6f879c1d" # AzureDatabricks Resource ID
  )

  $headers = @{
    'Content-Type' = 'application/x-www-form-urlencoded'
  }

  $body = @{
    grant_type    = "client_credentials"
    client_id     = $clientId
    client_secret = $clientSecret
    scope         = "$scope/.default"
  }

  $url = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
  $response = Invoke-RestMethod $url -Method 'POST' -Headers $headers -Body $body

  return $response.access_token
}