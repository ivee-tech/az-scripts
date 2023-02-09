@description('The name of the app service plan')
param hostingPlanName string

@allowed([
  'windows'
  'linux'
  'windows-container'
])
param os string

@allowed([
  'app'
  'functionapp'
])
@description('The kind of the app service plan')
param hostingPlanKind string = 'app'

@description('The name of ASE, required if the app is hosted in ASE')
param hostingEnvironment string = ''

@description('Describes plan\'s pricing tier and instance size. Check details at https://azure.microsoft.com/en-us/pricing/details/app-service/')
@allowed([
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'I1'
  'I2'
  'I3'
  'I1v2'
  'I2v2'
  'I3v2'
  'P1v3'
  'P2v3'
  'P3v3'
])
param skuName string = 'S1'

@description('Describes plan\'s instance count')
@minValue(1)
param skuCapacity int = 1

@description('Location for all resources.')
param location string = resourceGroup().location

resource hostingPlanName_resource 'Microsoft.Web/serverfarms@2020-09-01' = {
  name: hostingPlanName
  location: location
  kind: hostingPlanKind
  properties: {
    hostingEnvironment: ((!(hostingEnvironment == '')) ? hostingEnvironment : '')
    reserved: os == 'linux' ? true : false
    hyperV: os == 'windows-container' ? true : false
  }
  sku: {
    name: skuName
    capacity: skuCapacity
  }
}
