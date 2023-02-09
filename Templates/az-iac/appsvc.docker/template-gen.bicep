param subscriptionId string
param name string
param location string
param hostingPlanName string
param serverFarmResourceGroup string
param alwaysOn bool
param sku string
param skuCode string
param workerSize string
param workerSizeId string
param numberOfWorkers string
param linuxFxVersion string
param registryName string
param registryResourceGroupName string
param registryStartupCommand string

var registryResourceId = resourceId(subscriptionId, registryResourceGroupName, 'Microsoft.ContainerRegistry/registries', registryName)
var registryUrl = 'https://${registryName}.azurecr.io'
var isDocker = ((!(registryName == '')) ? true : false)

resource name_resource 'Microsoft.Web/sites@2018-11-01' = {
  name: name
  location: location
  tags: {}
  properties: {
    name: name
    siteConfig: {
      appSettings: [
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
          value: 'false'
        }
      ]
      linuxFxVersion: linuxFxVersion
      appCommandLine: registryStartupCommand
      alwaysOn: alwaysOn
    }
    serverFarmId: '/subscriptions/${subscriptionId}/resourcegroups/${serverFarmResourceGroup}/providers/Microsoft.Web/serverfarms/${hostingPlanName}'
    clientAffinityEnabled: false
  }
  dependsOn: [
    hostingPlanName_resource
  ]
}

resource hostingPlanName_resource 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: hostingPlanName
  location: location
  kind: 'linux'
  tags: {}
  properties: {
    name: hostingPlanName
    workerSize: workerSize
    workerSizeId: workerSizeId
    numberOfWorkers: numberOfWorkers
    reserved: true
  }
  sku: {
    tier: sku
    name: skuCode
  }
  dependsOn: []
}
