@description('The plan name for this web application.')
param hostingPlanName string

@description('The web application name. It must be unique across all Azure web apps. The application Url is https://[appName].azurewebsites.net')
param appName string

@description('Array with the names for the environment slots')
@maxLength(19)
param environments array = [
  'Staging'
]

@description('Location (region) for all resources.')
param location string = 'australiaeast'

@description('The SKU of App Service Plan')
param appServiceSku string = 'S1'
param dockerRegistryName string
param dockerRegistryResourceGroupName string
param dockerImageName string = '_MY_REGISTRY_USERNAME_.azurecr.io/_MY_NAMESPACE_/_MY_DOCKER_IMAGE_NAME_:_TAG_'
param dockerImageTag string
param isContainer bool = false

@allowed([
  'windows'
  'linux'
])
param os string

@allowed([
  'dotnet'
  'dotnetcore'
  'node'
  'java'
])
param stack string
param stackVersion string

@allowed([
  'app'
  'functionapp'
])
param kind string

@allowed([
  'app'
  'linux' // ???
  'functionapp'
  'app,linux'
  'functionapp,linux' // ???
  'app,container' // ???
  'app,linux,container'
])
param appKind string

var name = 'projectname-'
var webAppPortalName_var = appName
var appServicePlanName_var = hostingPlanName
var fxVersion = '${stack}|${stackVersion}'
var registryResourceId = resourceId(dockerRegistryResourceGroupName, 'Microsoft.ContainerRegistry/registries', dockerRegistryName)
var registryUrl = 'https://${dockerRegistryName}.azurecr.io'
var fullImageName = '${dockerRegistryName}.azurecr.io/${dockerImageName}:${dockerImageTag}'
var containerFxVersion = 'DOCKER|${fullImageName}'

resource appServicePlanName 'Microsoft.Web/serverfarms@2017-08-01' = {
  kind: kind
  name: appServicePlanName_var
  location: location
  properties: {
    reserved: os == 'linux' ? true : false
  }
  sku: {
    name: appServiceSku
  }
  dependsOn: []
}

resource webAppPortalName 'Microsoft.Web/sites@2016-08-01' = {
  name: webAppPortalName_var
  kind: appKind
  location: location
  properties: {
    name: webAppPortalName_var
    siteConfig: {
      linuxFxVersion: os == 'linux' ? (isContainer ? containerFxVersion : fxVersion) : null
      enabled: true
      appSettings: isContainer ? [
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: registryUrl
        } 
        {
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: listCredentials(registryResourceId, '2019-05-01').username
        } 
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: listCredentials(registryResourceId, '2019-05-01').passwords[0].value
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: false
        }
      ] : []
      netFrameworkVersion: stack == 'dotnet' ? stackVersion : null
      nodeVersion: stack == 'node' ? stackVersion : null
      javaVersion: stack == 'java' ? stackVersion : null
    }
    serverFarmId: appServicePlanName.id
  }
}

