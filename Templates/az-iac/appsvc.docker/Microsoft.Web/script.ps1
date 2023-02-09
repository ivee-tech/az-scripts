$resourceGroupName = 'awe'

# App Plan

$filePath = '.\Microsoft.Web.ServerFarmsTmp.json'

# deploy linux app plan (works for linux containers as well)
$os = 'linux'
$hostingPlanKind = 'app'
$hostingPlanName = 'linux-plan'
$skuName = 'S1'
New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName `
  -TemplateFile $filePath -Mode Incremental `
  -hostingPlanName $hostingPlanName -os $os -skuName $skuName

# deploy windows app plan
$os = 'windows'
$hostingPlanKind = 'app'
$hostingPlanName = 'win-plan'
$skuName = 'S1'
New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName `
  -TemplateFile $filePath -Mode Incremental `
  -hostingPlanName $hostingPlanName -os $os -skuName $skuName

# deploy windows container app plan
$resourceGroupName = 'aac'
$os = 'windows-container'
$hostingPlanKind = 'app'
$hostingPlanName = 'win-container-plan'
$skuName = 'P1v3'
New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName `
  -TemplateFile $filePath -Mode Incremental `
  -hostingPlanName $hostingPlanName -os $os -skuName $skuName


# App Service

$appName = 'app-002'
$filePath = '.\Microsoft.Web.Sites.ContainerTmp.json'

# deploy dotnet v5.0 on win
$hostingPlanName = 'win-plan'
$appKind = 'app'
$keyVaultName = 'dakv1'
$runFromPackage = '0'
$stack = 'dotnet'
$stackVersion = '5.0'
New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName `
  -TemplateFile $filePath -Mode Incremental `
  -hostingPlanName $hostingPlanName -appName $appName -appKind $appKind -keyVaultName $keyVaultName -runFromPackage $runFromPackage `
  -stack $stack -stackVersion $stackVersion `

#########################################

# deploy java v11 on win
# additional configuration may be required for Java web server, version, etc.
$hostingPlanName = 'win-plan'
$appKind = 'app'
$keyVaultName = 'dakv1'
$runFromPackage = '0'
$stack = 'java'
$stackVersion = '11'
New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName `
  -TemplateFile $filePath <#-TemplateParameterFile $paramFilePath#> -Mode Incremental `
  -hostingPlanName $hostingPlanName -appName $appName -appKind $appKind -keyVaultName $keyVaultName -runFromPackage $runFromPackage `
  -stack $stack -stackVersion $stackVersion `

#########################################

# deploy node 14-lts on linux
$hostingPlanName = 'linux-plan'
$appKind = 'app,linux'
$keyVaultName = 'dakv1'
$runFromPackage = '0'
$stack = 'node'
$stackVersion = '14-lts'
New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName `
  -TemplateFile $filePath <#-TemplateParameterFile $paramFilePath#> -Mode Incremental `
  -hostingPlanName $hostingPlanName -appName $appName -appKind $appKind -keyVaultName $keyVaultName -runFromPackage $runFromPackage `
  -stack $stack -stackVersion $stackVersion `

###########################################

# deploy dotnet 5.0 on linux
$hostingPlanName = 'linux-plan'
$appKind = 'app,linux'
$keyVaultName = 'dakv1'
$runFromPackage = '0'
$stack = 'dotnetcore'
$stackVersion = '5.0'
New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName `
  -TemplateFile $filePath <#-TemplateParameterFile $paramFilePath#> -Mode Incremental `
  -hostingPlanName $hostingPlanName -appName $appName -appKind $appKind -keyVaultName $keyVaultName -runFromPackage $runFromPackage `
  -stack $stack -stackVersion $stackVersion `

###########################################

# deploy dotnet function app on windows
$hostingPlanName = 'win-plan'
$appKind = 'functionapp'
$keyVaultName = 'dakv1'
$runFromPackage = '0'
$storageConnectionString = '***'
$runtimeStack = 'dotnet'
New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName `
  -TemplateFile $filePath -Mode Incremental `
  -hostingPlanName $hostingPlanName -appName $appName -appKind $appKind -keyVaultName $keyVaultName -runFromPackage $runFromPackage `
  -stack $stack -stackVersion $stackVersion `
  -storageConnectionString $storageConnectionString

###########################################

# deploy dotnet function app on linux
$hostingPlanName = 'linux-plan'
$appKind = 'functionapp,linux'
$keyVaultName = 'dakv1'
$runFromPackage = '0'
$storageConnectionString = '***'
$runtimeStack = 'dotnet'
New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName `
  -TemplateFile $filePath <#-TemplateParameterFile $paramFilePath#> -Mode Incremental `
  -hostingPlanName $hostingPlanName -appName $appName -appKind $appKind -keyVaultName $keyVaultName -runFromPackage $runFromPackage `
  -stack $stack -stackVersion $stackVersion `
  -storageConnectionString $storageConnectionString `


###########################################

# deploy app with linux container
$hostingPlanName = 'linux-plan'
$appKind = 'app,linux,container'
$keyVaultName = 'dakv1'
$runFromPackage = '0'
$dockerRegistryResourceGroupName = 'auto-testing'
$dockerRegistryName = 'autotestingacr'
$dockerImageName = 'test-web'
$dockerImageTag = '0.0.1'
New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName `
  -TemplateFile $filePath -Mode Incremental `
  -hostingPlanName $hostingPlanName -appName $appName -appKind $appKind -keyVaultName $keyVaultName -runFromPackage $runFromPackage `
  -dockerRegistryResourceGroupName $dockerRegistryResourceGroupName -dockerRegistryName $dockerRegistryName `
  -dockerImageName $dockerImageName -dockerImageTag $dockerImageTag

###########################################

# deploy app with windows container
$hostingPlanName = 'win-container-plan'
$appKind = 'app,container'
$keyVaultName = 'aac-kv-001'
$runFromPackage = '0'
$dockerRegistryResourceGroupName = 'auto-testing'
$dockerRegistryName = 'autotestingacr'
$dockerImageName = 'test-web'
$dockerImageTag = '0.0.1'
New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName `
  -TemplateFile $filePath -Mode Incremental `
  -hostingPlanName $hostingPlanName -appName $appName -appKind $appKind -keyVaultName $keyVaultName -runFromPackage $runFromPackage `
  -stack $stack -stackVersion $stackVersion `
   -dockerRegistryResourceGroupName $dockerRegistryResourceGroupName -dockerRegistryName $dockerRegistryName `
   -dockerImageName $dockerImageName -dockerImageTag $dockerImageTag

