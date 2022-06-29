function Add-MsiAccess(
  [Parameter(Mandatory = $true)]
  [EnvironmentConfig] $environmentConfig,

  [Parameter(Mandatory = $true)]
  [NamingConfig] $namingConfig,

  [Parameter(Mandatory = $false)]
  [ValidateSet('api', 'spn', 'app', 'https')]
  [string]
  $appType = "api",

  [Parameter(Mandatory=$true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $msiId,

  [Parameter(Mandatory=$false)]
  [string[]]
  $requiredRoles = $null
) {

  # import utility functions
  . "$PSScriptRoot\..\utilities\deploy.naming.ps1"

  $appUri = Get-AppIdentityUri `
    -type $appType `
    -environmentConfig $environmentConfig `
    -namingConfig $namingConfig
  $spnId = az ad sp list `
    --spn $appUri `
    --query [-1].id

  Throw-WhenError -output $spnId

  $roles = az ad sp show `
      --id $spnId `
      --query appRoles `
      | ConvertFrom-Json

  Throw-WhenError -output $roles

  if ($null -eq $requiredRoles) {
    $requiredRoles = @("include-all")
    Write-Host "Assigning all available roles"
  }

  $existingAssignments = (az rest `
    --method GET `
    --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$msiId/appRoleAssignments?`$filter=resourceId eq $spnId" `
    --headers 'Content-Type=application/json' `
    | ConvertFrom-Json).value

  Throw-WhenError -output $existingAssignments

  foreach ($roleValue in $requiredRoles) {
    foreach ($role in $roles) {
      if ($roleValue -eq $role.value -or $roleValue -eq "include-all") {

        if ($existingAssignments.appRoleId -contains $($role.id)){
          Write-Host "API Permission $($role.value) Already Assigned"
        } else {
          Write-Host "Assign API Permission $($role.value)"
          $output = az rest `
          --method POST `
          --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$msiId/appRoleAssignments" `
          --body "{\`"appRoleId\`": \`"$($role.id)\`",\`"principalId\`": \`"$msiId\`",\`"resourceId\`": \`"$spnId\`"}" `
          --headers 'Content-Type=application/json'

          Throw-WhenError -output $output
        }
      }
    }
  }
}