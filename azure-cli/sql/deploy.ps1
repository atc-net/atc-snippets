param (
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $resourceGroupName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $sqlServerName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $dbName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $keyVaultName,

  [Parameter(Mandatory = $false)]
  [string]
  $location = "westeurope",

  [Parameter(Mandatory = $false)]
  [string[]]
  $resourceTags = @()
)

#############################################################################################
# Configure names and options
#############################################################################################
Write-Host "Provision Azure SQL server" -ForegroundColor DarkGreen

# import utility functions
. "$PSScriptRoot\..\utilities\New-Password.ps1"
. "$PSScriptRoot\get_SqlConnectionString.ps1"

#############################################################################################
# Resource naming section
#############################################################################################

$sqlServerUserName = 'sqlsrvadmin'
$defaultDbSpecs = @{edition = "Standard"; serviceObjective = "s0"; maxDataSize = 250GB; zoneRedundant = $False }
$readUser = @{Name = "ReadDbUser"; Password = ""; Read = $True; Write = $False; Create = $False; Exec = $False }
$sqlDatabases = @(
  @{ Area = 'Default'; Name = $dbName; ConnnectionName = 'DefaultSqlConnection'; Users = @($readUser); Spec = $defaultDbSpecs }
)

#############################################################################################
# Configure key vault secrets
#############################################################################################
Write-Host "Configure key vault secrets " -ForegroundColor DarkGreen

Write-Host "  Querying SqlServerPassword secret" -ForegroundColor DarkYellow
$sqlServerPassword = az keyvault secret show `
  --name 'SqlServerPassword' `
  --vault-name $keyVaultName `
  --query value `
  --output tsv

if (!$?) {
  Write-Host "  Creating SqlServerPassword secret" -ForegroundColor DarkYellow
  $sqlServerPassword = New-Password -Length 20 -AvoidCharacters "'"
  $output = az keyvault secret set `
    --vault-name $keyVaultName `
    --name "SqlServerPassword" `
    --value $sqlServerPassword

  Throw-WhenError -output $output
}
else {
  Write-Host "  SqlServerPassword already exists, skipping creation" -ForegroundColor DarkYellow
}

# Add Passwords for each db user on each database to key vault
foreach ($sqlDatabase in $sqlDatabases) {
  $sqlDatabaseUsers = $sqlDatabase.Users

  foreach ($sqlDatabaseUser in $sqlDatabaseUsers) {
    $username = $sqlDatabaseUser.Name
    $passwordName = ($username + "Password")

    Write-Host "  Querying $passwordName secret" -ForegroundColor DarkYellow
    $password = az keyvault secret show `
      --name $passwordName `
      --vault-name $keyVaultName `
      --query value `
      --output tsv

    if ($LastExitCode -gt 0) {
      Write-Host "  Creating $passwordName secret" -ForegroundColor DarkYellow
      $password = New-Password -Length 20 -AvoidCharacters "'"
      $output = az keyvault secret set `
        --vault-name $keyVaultName `
        --name $passwordName `
        --value $password

      Throw-WhenError -output $output

    }
    else {
      Write-Host "  $passwordName already exists, skipping creation" -ForegroundColor DarkYellow
    }

    $sqlDatabaseUser.Password = $password
  }
}

$defaultDbConnectionString = "";

# Add ConnectionString for each database to key vault
foreach ($sqlDatabase in $sqlDatabases) {
  $sqlArea = $sqlDatabase.Area
  $sqlDatabaseName = $sqlDatabase.Name
  $sqlConnectionName = $sqlDatabase.ConnnectionName

  Write-Host "  Querying $sqlArea SqlConnection secret" -ForegroundColor DarkYellow
  $sqlConnectionString = Get-SqlConnectionString `
    -server $sqlServerName `
    -database $sqlDatabaseName `
    -user $sqlServerUserName `
    -password $sqlServerPassword

  if ($sqlArea -eq "Default") {
    $defaultDbConnectionString = $sqlConnectionString
  }

  $output = az keyvault secret show `
    --name $sqlConnectionName `
    --vault-name $keyVaultName `
    --query value `
    --output tsv

  if ($sqlConnectionString -ne $output) {
    Write-Host "  Creating $sqlArea SqlConnection secret" -ForegroundColor DarkYellow
    $output = az keyvault secret set `
      --vault-name $keyVaultName `
      --name $sqlConnectionName `
      --value $sqlConnectionString

    Throw-WhenError -output $output
  }
  else {
    Write-Host "  $sqlArea SqlConnection already exists, skipping creation" -ForegroundColor DarkYellow
  }
}

#############################################################################################
# Provision sql server resource
#############################################################################################
Write-Host " Creating sql server" -ForegroundColor DarkGreen
$output = az sql server create `
  --name $sqlServerName `
  --location $location `
  --resource-group $resourceGroupName `
  --admin-password """$sqlServerPassword""" `
  --admin-user $sqlServerUserName

Throw-WhenError -output $output

Write-Host "  Tagging sql server" -ForegroundColor DarkYellow
$output = az resource tag `
  --resource-type "Microsoft.Sql/servers" `
  --name $sqlServerName `
  --resource-group $resourceGroupName `
  --tags $resourceTags

Throw-WhenError -output $output

Write-Host "  Configuring sql server firewall rules" -ForegroundColor DarkYellow
$output = az sql server firewall-rule create `
  --server $sqlServerName.ToLower() `
  --resource-group $resourceGroupName `
  --name 'AllowAllWindowsAzureIps' `
  --start-ip-address '0.0.0.0' `
  --end-ip-address '0.0.0.0'

Throw-WhenError -output $output

#############################################################################################
# Provision sql database logins
#############################################################################################
Write-Host " Provision sql logins" -ForegroundColor DarkGreen

$sqlServerInstance = $sqlServerName + ".database.windows.net"

# Add login for each user on each database
foreach ($sqlDatabase in $sqlDatabases) {
  $sqlDatabaseUsers = $sqlDatabase.Users

  foreach ($sqlDatabaseUser in $sqlDatabaseUsers) {
    $username = $sqlDatabaseUser.Name
    $password = $sqlDatabaseUser.Password

    $queryVariables = "Username=$username", "Password=$password"

    Write-Host "  Creating database login for $username" -ForegroundColor DarkYellow
    Invoke-Sqlcmd -ServerInstance $sqlServerInstance `
      -Database master `
      -Username $sqlServerUserName `
      -Password $sqlServerPassword `
      -InputFile createlogin.sql `
      -Variable $queryVariables `
      -verbose
  }
}

#############################################################################################
# Provision sql database resource
#############################################################################################
Write-Host "Provision sql databases with users" -ForegroundColor DarkGreen

# Add users for each database
foreach ($sqlDatabase in $sqlDatabases) {
  $sqlArea = $sqlDatabase.Area
  $sqlDatabaseName = $sqlDatabase.Name
  $sqlDatabaseUsers = $sqlDatabase.Users
  $sqlDatabaseSpec = $sqlDatabase.Spec

  Write-Host "  Creating $sqlArea sql database" -ForegroundColor DarkYellow
  $output = ProvisionSqlDb `
    -resourceGroupName $resourceGroupName `
    -sqlServerName $sqlServerName `
    -sqlDatabaseName $sqlDatabaseName `
    -sqlDatabaseSpec $sqlDatabaseSpec `
    -resourceTags $resourceTags
  Throw-WhenError -output $output

  foreach ($sqlDatabaseUser in $sqlDatabaseUsers) {
    $username = $sqlDatabaseUser.Name
    $ReadRights = $sqlDatabaseUser.Read
    $WriteRights = $sqlDatabaseUser.Write
    $CreateRights = $sqlDatabaseUser.Create
    $ExecRights = $sqlDatabaseUser.Exec

    $queryVariables = "Username=$username", "ReadRights=$ReadRights", "WriteRights=$WriteRights", "CreateRights=$CreateRights", "ExecRights=$ExecRights"

    Write-Host "  Creating $username on $sqlArea sql database" -ForegroundColor DarkYellow
    Invoke-Sqlcmd -ServerInstance $sqlServerInstance `
      -Database $sqlDatabaseName `
      -Username $sqlServerUserName `
      -Password $sqlServerPassword `
      -InputFile createdbuser.sql `
      -Variable $queryVariables `
      -verbose
  }
}