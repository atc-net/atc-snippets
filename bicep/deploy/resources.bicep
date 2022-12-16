targetScope = 'resourceGroup'

@allowed([
  'DevTest'
  'Production'
])
@maxLength(10)
@description('The environment type')
param environmentType string = 'DevTest'

@description('Optional. Location for resource.')
param location string = resourceGroup().location

@description('The resource name')
param resourceName string

@description('Metadata Tags for the resouce')
param tags object

var environmentConfig = loadJsonContent('config-environment.json')['${environmentType}']

module storageAccount './modules/storageAccount.bicep' = {
  name: 'StorageAccount'
  params: {
    location: location
    resourceName: resourceName
    storageSKU: 'Standard_LRS'
    tags: tags
  }
}

module serviceBusNamespace './modules/serviceBusNamespace.bicep' = {
  name: 'ServiceBusNamespace'
  params: {
    location: location
    resourceName: resourceName
    serviceBusSKU: environmentConfig.ServiceBusNamespace.Sku
    tags: tags
  }
}

module logAnalyticsWorkspace 'modules/logAnalyticsWorkspace.bicep' = {
  name: 'LogAnalyticsWorkspace'
  params: {
    location: location
    logAnalyticsSKU: environmentConfig.LogAnalyticsWorkspace.Sku
    resourceName: resourceName
    tags: tags
  }
}
