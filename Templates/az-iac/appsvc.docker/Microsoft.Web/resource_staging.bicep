resource webAppPortalName_staging 'Microsoft.Web/sites/slots@2018-11-01' = {
  parent: webAppPortalName
  name: 'staging'
  kind: 'app,linux,container'
  location: location
  properties: {
    siteConfig: {
      linuxFxVersion: 'DOCKER|${dockerImageName}'
      enabled: true
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: registryUrl
        }
      ]
    }
    serverFarmId: appServicePlanName.id
  }
}
