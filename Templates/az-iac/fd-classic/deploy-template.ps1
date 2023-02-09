$resourceGroupName = 'daff-demo'
$filePath = '.\azuredeploy.json'
$paramFilePath = '.\azuredeploy.parameters.json'

$frontDoorName = 'daff-fd-001'
$backendAddress = 'ets-demo-test.azurewebsites.net'
New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName `
  -TemplateFile $filePath <#-TemplateParameterFile $paramFilePath#> -Mode Incremental `
  -frontDoorName $frontDoorName -backendAddress $backendAddress




$filePath = '.\main.bicep'
az deployment group create `
  --resource-group $resourceGroupName `
  --template-file $filePath `
  --parameters @$paramFilePath `
  --parameters `
  frontDoorName="$frontDoorName" backendAddress="$backendAddress"

