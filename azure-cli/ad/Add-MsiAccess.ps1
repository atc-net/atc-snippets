function Add-MsiAccess {
  param(
    [Parameter(Mandatory = $true)]
    [EnvironmentConfig]
    $EnvironmentConfig,

    [Parameter(Mandatory = $true)]
    [NamingConfig]
    $NamingConfig,

    [Parameter(Mandatory = $false)]
    [ValidateSet('api', 'spn', 'app', 'https')]
    [string]
    $AppType = "api",

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $MsiId,

    [Parameter(Mandatory = $false)]
    [string[]]
    $RequiredRoles = $null
  )

  # import utility functions
  . "$PSScriptRoot\..\utilities\deploy.naming.ps1"
  . "$PSScriptRoot\..\utilities\deploy.utilities.ps1"

  $appUri = Get-AppIdentityUri `
    -type $AppType `
    -environmentConfig $EnvironmentConfig `
    -namingConfig $NamingConfig

  $spnId = az ad sp list `
    --spn $appUri `
    --query [-1].id `
    --out tsv

  Throw-WhenError -output $spnId

  $roles = az ad sp show `
    --id $spnId `
    --query appRoles `
  | ConvertFrom-Json

  Throw-WhenError -output $roles

  if ($null -eq $RequiredRoles) {
    $RequiredRoles = @("include-all")
    Write-Host "  Assigning all available roles" -ForegroundColor DarkYellow
  }

  $existingAssignments = (az rest `
      --method GET `
      --headers "Content-Type=application/json" `
      --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$MsiId/appRoleAssignments?`$filter=resourceId eq $spnId" `
    | ConvertFrom-Json).value

  Throw-WhenError -output $existingAssignments

  foreach ($roleValue in $RequiredRoles) {
    foreach ($role in $roles) {
      if ($roleValue -eq $role.value -or $roleValue -eq "include-all") {

        Write-Host "  Assigning $($role.value) " -ForegroundColor DarkYellow -NoNewline

        if ($existingAssignments.appRoleId -contains $($role.id)) {
          Write-Host " -> Already assigned" -ForegroundColor Cyan
        }
        else {
          $body = @{
            appRoleId = $role.id
            principalId = $MsiId
            resourceId = $spnId
          }

          $output = az rest `
          --method POST `
          --headers "Content-Type=application/json" `
          --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$MsiId/appRoleAssignments" `
          --body (ConvertTo-RequestJson $body)

          Throw-WhenError -output $output

          Write-Host " -> Permission assigned" -ForegroundColor Cyan
        }
      }
    }
  }
}