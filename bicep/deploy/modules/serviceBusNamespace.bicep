@description('Optional. Location for resource.')
param location string = resourceGroup().location

param resourceName string

@allowed([
  'Basic'
  'Premium'
  'Standard'
])
param serviceBusSKU string = 'Standard'

param tags object

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' = {
  name: resourceName
  location: location
  tags: empty(tags) ? null : tags
  sku: {
    name: serviceBusSKU
    tier: serviceBusSKU
    capacity: 1
  }
  properties: {
    minimumTlsVersion: '1.2'
  }
}
