function Set-DatabricksSpnAdminUser {
  param (
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $tenantId,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $clientId,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [System.Security.Cryptography.X509Certificates.X509Certificate2]
    $certificate,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $workspaceUrl,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $resourceId
  )

  # import utility functions
  . "$PSScriptRoot\get_OAuthToken.ps1"

  $bearerToken = Get-OAuthTokenUsingCertificate `
    -tenantId $tenantId `
    -clientId $clientId `
    -certificate $certificate

  $managementToken = Get-OAuthTokenUsingCertificate `
    -tenantId $tenantId `
    -clientId $clientId `
    -certificate $certificate `
    -scope "https://management.core.windows.net/"

  # Calling any Azure Databricks API endpoint with a SPN management token and the resource ID
  # Will automatically add the SPN as an admin user in Databricks
  # See https://docs.microsoft.com/en-us/azure/databricks/dev-tools/api/latest/aad/service-prin-aad-token#admin-user-login

  $headers = @{
    'Authorization' = "Bearer $bearerToken"
    'X-Databricks-Azure-SP-Management-Token' = $managementToken
    'X-Databricks-Azure-Workspace-Resource-Id' = $resourceId
  }

  $response = Invoke-WebRequest `
    -Uri "https://$workspaceUrl/api/2.0/clusters/list-node-types" `
    -Method 'GET' `
    -Headers $headers

  if ($response.StatusCode -ne 200) {
    Write-Error $response.StatusDescription
    throw
  }

  return $bearerToken
}