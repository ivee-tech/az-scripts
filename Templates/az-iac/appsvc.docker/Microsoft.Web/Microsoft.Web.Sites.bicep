@description('Add Diagnostic Settings to App Services')
param addDiagnosticSettings bool = false

@description('Inbound network access restrictions.')
param accessRestrictions array = []

@description('The type of application, i.e. web app or function app')
@allowed([
  'app'
  'functionapp'
  'app,linux,container'
])
param appKind string

@description('App insights instrumentation key. Required because Azure portal fails if using a keyvault reference for AI')
param applicationInsightsInstrumentationKey string

@description('Name of the application insights resource.')
param applicationInsightsName string

@description('Specifies the name of the instrumentation key secret')
param applicationInsightsSecretName string = 'AiInstrumentationKey'

@description('The name of the web application or function application')
param appName string

@description('Specifies the permissions to certificates in the vault')
param certificatePermissions array = []

@description('Custom application configuration settings to be used in addition to default settings')
param configCustom object = {}

@description('DotNet Core version that function app targets')
@allowed([
  '~3'
  '~2'
  '~1'
])
param extensionVersion string = '~3'

@description('The name of the app service plan')
param hostingPlanName string

@description('Specifies the permissions to keys in the vault')
param keyPermissions array = []

@description('Specifies the name of the key vault that stores connection strings and other app secrets')
param keyVaultName string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Required if network components are in a different resource group')
param networkResourceGroupName string = resourceGroup().location

@description('Optional, only required if assigning function app to subnet')
param networkSubnetName string = ''

@description('Optional, only required if assigning function app to subnet')
param networkVnetName string = ''

@description('Resource group name for Log Analytic Workspace')
param omsWorkspaceRG string = ''

@description('The name for Log Analytic Workspace')
param omsWorkspaceName string = ''

@description('Application run from package')
param runFromPackage string = '1'

@description('Pick the language runtime that you want enabled')
@allowed([
  'powershell'
  'dotnet'
  'node'
  'java'
])
param runtimeStack string

@description('Specifies the permissions to secrets in the vault')
param secretPermissions array = []

@description('Name of the staging slot if used. Required for blue green / outageless deployments')
param stagingSlotName string = ''

@description('Storage account connection string')
param storageConnectionString string = ''

@description('Id of subscription that all resources belong to. Only required if connecting to subnet or applying inbound network restrictions')
param subscriptionId string = subscription().subscriptionId

@description('Specifies the Azure Active Directory tenant ID that should be used for authenticating requests to the key vault. Get it by using Get-AzSubscription cmdlet.')
param tenantId string = subscription().tenantId

var emptyArray = []
var networkVnetId = resourceId(subscriptionId, networkResourceGroupName, 'Microsoft.Network/virtualNetworks', networkVnetName)
var networkSubnetId = '${networkVnetId}/subnets/${networkSubnetName}'
var functionAppAllowedOrigins = [
  'https://functions.azure.com'
  'https://functions-staging.azure.com'
  'https://functions-next.azure.com'
]
var omsWorkspaceID = resourceId(omsWorkspaceRG, 'Microsoft.OperationalInsights/workspaces', omsWorkspaceName)
var configDefault = {
  APPINSIGHTS_INSTRUMENTATIONKEY: applicationInsightsInstrumentationKey
  APPINSIGHTS_PROFILERFEATURE_VERSION: '1.0.0'
  AzureWebJobsStorage: storageConnectionString
  ApplicationInsightsAgent_EXTENSION_VERSION: '~2'
  DiagnosticServices_EXTENSION_VERSION: '~3'
  InstrumentationEngine_EXTENSION_VERSION: '~1'
  XDT_MicrosoftApplicationInsights_BaseExtensions: '~1'
  XDT_MicrosoftApplicationInsights_Mode: 'recommended'
  WEBSITE_RUN_FROM_PACKAGE: runFromPackage
}
var configWebApp = {}
var configFunctionApp = {
  FUNCTIONS_WORKER_RUNTIME: runtimeStack
  FUNCTIONS_EXTENSION_VERSION: extensionVersion
  WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: storageConnectionString
  WEBSITE_CONTENTSHARE: toLower(appName)
}
var configSite = union(configCustom, configDefault, ((appKind == 'app') ? configWebApp : configFunctionApp))

resource appName_Microsoft_Insights_appName_diags 'Microsoft.Web/sites/providers/diagnosticSettings@2017-05-01-preview' = if (addDiagnosticSettings == true) {
  name: '${appName}/Microsoft.Insights/${appName}-diags'
  properties: {
    workspaceId: omsWorkspaceID
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
  dependsOn: [
    appName_resource
  ]
}

resource appName_resource 'Microsoft.Web/sites@2018-11-01' = {
  name: appName
  location: location
  kind: appKind
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: resourceId('Microsoft.Web/serverfarms', hostingPlanName)
  }
}

resource appName_virtualNetwork 'Microsoft.Web/sites/networkConfig@2019-08-01' = if (!(networkSubnetName == '')) {
  parent: appName_resource
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: networkSubnetId
    isSwift: true
  }
}

resource appName_appsettings 'Microsoft.Web/sites/config@2020-09-01' = {
  parent: appName_resource
  name: 'appsettings'
  properties: configSite
}

resource appName_stagingSlotName_staging_stagingSlotName 'Microsoft.Web/sites/slots@2020-09-01' = if (!(stagingSlotName == '')) {
  parent: appName_resource
  name: '${((stagingSlotName == '') ? 'staging' : stagingSlotName)}'
  location: location
  kind: appKind
  properties: {
    serverFarmId: resourceId('Microsoft.Web/serverfarms', hostingPlanName)
  }
}

resource appName_web 'Microsoft.Web/sites/config@2018-11-01' = {
  parent: appName_resource
  name: 'web'
  location: location
  properties: {
    cors: {
      allowedOrigins: ((appKind == 'functionapp') ? functionAppAllowedOrigins : emptyArray)
      supportCredentials: false
    }
    ipSecurityRestrictions: accessRestrictions
  }
}

resource keyVaultName_add 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = {
  name: '${keyVaultName}/add'
  properties: {
    accessPolicies: [
      {
        tenantId: tenantId
        objectId: reference('Microsoft.Web/sites/${appName}', '2018-11-01', 'Full').identity.principalId
        permissions: {
          keys: keyPermissions
          secrets: secretPermissions
          certificates: certificatePermissions
        }
      }
    ]
  }
  dependsOn: [
    appName_resource
  ]
}
