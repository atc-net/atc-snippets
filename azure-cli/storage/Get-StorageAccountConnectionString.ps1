function Get-StorageAccountConnectionString {
  param (
    [Parameter(Mandatory = $true)]
    [Alias("Name")]
    [string]
    $StorageAccountName,

    [Parameter(Mandatory = $true)]
    [string]
    $ResourceGroupName
  )

  Write-Host "  Getting ConnectionString for Storage Account '$storageAccountName'" -ForegroundColor DarkYellow

  $connectionString = az storage account show-connection-string `
    --name $StorageAccountName `
    --resource-group $ResourceGroupName `
    --query connectionString `
    --output tsv

  Throw-WhenError -output $connectionString

  return $connectionString
}