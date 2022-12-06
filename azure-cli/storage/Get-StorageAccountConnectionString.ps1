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

  $output = az storage account keys list `
    --account-name $StorageAccountName `
    --resource-group $ResourceGroupName `
    --query "[?keyName=='key1'] | [0].value" `
    --output tsv

  Throw-WhenError $output

  return `
    "DefaultEndpointsProtocol=https;" + `
    "EndpointSuffix=core.windows.net;" + `
    "AccountName=$StorageAccountName;" + `
    "AccountKey=$output"
}