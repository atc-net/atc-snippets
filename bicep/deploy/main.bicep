targetScope = 'subscription'

@allowed([
  'Dev'
  'Test'
  'Prod'
])
@maxLength(4)
@description('The environment name')
param environmentName string = 'Dev'

@allowed([
  'DevTest'
  'Production'
])
@maxLength(10)
@description('The environment type')
param environmentType string = 'DevTest'

@allowed([
  'westeurope'
])
@description('Location of resource group and resources')
param location string

// Configurations
var constants = loadJsonContent('config-constants.json')
var tags = loadJsonContent('config-tags.json')['${environmentType}']

// Naming
var resourceGroupName = '${constants.SystemName}-${toUpper(environmentName)}'
var resourceName = '${constants.CompanyAbbreviation}${constants.SystemAbbreviation}${toLower(environmentName)}'

// Resource Group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: location
  tags: tags
  properties: {
  }
}

// Resources
module resources 'resources.bicep' = {
  name: 'Resources'
  scope: resourceGroup
  params: {
    environmentType: environmentType
    resourceName: resourceName
    location: location
    tags: tags
  }
}
