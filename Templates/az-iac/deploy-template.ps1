$resourceGroupName = 'awe'
$filePath = '.\appsvc.docker\Microsoft.Web\Microsoft.Web.Sites.ContainerTmp.json'
$paramFilePath = '.\appsvc.docker\Microsoft.Web\Microsoft.Web.Sites.ContainerTmp.parameters.json'

$appName = 'app-002'
$hostingPlanName = 'linux-plan'
$appKind = 'functionapp,linux' # 'app,container' # ,linux,container' # 'linux'
$keyVaultName = 'dakv1'
#$keyVaultName = 'aac-kv-001'
$runFromPackage = '0'
$storageConnectionString = '***'
#$stack = 'dotnetcore'
#$stackVersion = '5.0'
#$stack = 'java'
#$stackVersion = '11'
#$stack = 'dotnetcore'
#$stackVersion = 'v3.1'
#$stack = 'node'
#$stackVersion = '14-lts'
$runtimeStack = 'dotnet'
$dockerRegistryResourceGroupName = 'auto-testing'
$dockerRegistryName = 'autotestingacr'
$dockerImageName = 'test-web'
$dockerImageTag = '0.0.1'
New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName `
  -TemplateFile $filePath <#-TemplateParameterFile $paramFilePath#> -Mode Incremental `
  -hostingPlanName $hostingPlanName -appName $appName -appKind $appKind -keyVaultName $keyVaultName -runFromPackage $runFromPackage `
  -stack $stack -stackVersion $stackVersion `
  -storageConnectionString $storageConnectionString `
   -dockerRegistryResourceGroupName $dockerRegistryResourceGroupName -dockerRegistryName $dockerRegistryName `
   -dockerImageName $dockerImageName -dockerImageTag $dockerImageTag

Remove-AzWebApp -ResourceGroupName $resourceGroupName -Name $appName -Force

$resourceGroupName = 'aac'
$filePath = '.\appsvc.docker\Microsoft.Web\Microsoft.Web.ServerFarmsTmp.json'
$os = 'windows-container'
$hostingPlanKind = 'app'
$hostingPlanName = 'win-container-plan'
$skuName = 'P1v3'
New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName `
  -TemplateFile $filePath <#-TemplateParameterFile $paramFilePath#> -Mode Incremental `
  -hostingPlanName $hostingPlanName -os $os -skuName $skuName


Remove-AzAppServicePlan -ResourceGroupName $resourceGroupName -Name $hostingPlanName -Force



$filePath = '.\appsvc.docker\template.bicep'
az deployment group create `
  --resource-group $resourceGroupName `
  --template-file $filePath `
  --parameters @$paramFilePath `
  --parameters `
  linuxFxVersion="$linuxFxVersion" dockerRegistryPassword="$dockerRegistryPassword"

$appName = 'dawr-demo-docker2'
$appPlanName = "$appName-plan"
$img = 'elnably/dockerimagetest'
az appservice plan create -n $appPlanName -g $resourceGroupName --is-linux
az webapp create -n $appName -g $resourceGroupName -p $appPlanName -i $img
