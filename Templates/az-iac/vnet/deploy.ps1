$resourceGroupName = 'awe'
$filePath = '.\azuredeploy.json'
$paramFilePath = '.\azuredeploy.parameters.json'

$vnetName = 'awe-vnet'
$vnetAddressPrefix = '172.17.0.0/16'
$subnet1Name = 'default'
$subnet1Prefix = '172.17.0.0/24'
$subnet2Name = 'subnet2'
$subnet2Prefix = '172.17.1.0/24'
New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName `
  -TemplateFile $filePath -TemplateParameterFile $paramFilePath -Mode Incremental `
    -vnetName $vnetName -vnetAddressPrefix $vnetAddressPrefix -subnet1Name $subnet1Name -subnet1Prefix $subnet1Prefix `
    -subnet2Name $subnet2Name -subnet2Prefix $subnet2Prefix


  