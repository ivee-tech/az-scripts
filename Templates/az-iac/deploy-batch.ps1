$resourceGroupName = 'awe'
$filePath = '.\batchaccount-with-storage\azuredeploy.json'
$paramFilePath = '.\batchaccount-with-storage\azuredeploy.parameters.json'

# deploy batch account using ARM template
$batchAccountName = 'awebatch'
$storageAccountsku = 'Standard_LRS'
New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName `
  -TemplateFile $filePath <#-TemplateParameterFile $paramFilePath#> -Mode Incremental `
  -batchAccountName $batchAccountName -storageAccountsku $storageAccountsku


# login into the batch account
az batch account login `
    --name $batchAccountName `
    --resource-group $resourceGroupName `
    --shared-key-auth

# handy script to get the avaiable locations, publishers, offers, and image skus, check the $skus variable value
Get-AzLocation

$location = 'AustraliaCentral'
$publisherFilter = '*Canonical*' # '*Bionic*' # '*Canonical*' # '*cloudera*' # '*redhat*' # '*Atomic*' # '*Microsoft*' # Microsoft, Canonical, credativ

Get-AzVMImagePublisher -Location $location | Where-Object { $_.PublisherName -like $publisherFilter }

$publisherName = 'Canonical' # 'MicrosoftWindowsServer' # 'MicrosoftVisualStudio' # 'MicrosoftWindowsServer' # 'MicrosoftWindowsDesktop' # 'cloudera' # 'RedHat' # 'atomicorp' # 'MicrosoftVisualStudio' # 'MicrosoftVisualStudio' # 'MicrosoftSqlServer' # 'MicrosoftWindowsServer' # 'MicrosoftSqlServer'
$offers = Get-AzVMImageOffer -Location $location -PublisherName $publisherName

$offer = 'UbuntuServer' # 'UbuntuServer' # 'Ubuntu_Core' # 'WindowsServerSemiAnnual' # 'WindowsServer' # 'sql2019-ws2019' # 'windows-10' #'cloudera-centos-os' # 'RHEL' # 'secure-os' # 'visualstudio2019latest' # 'SQL2017-WS2016' # 'visualstudio2019latest' # 'UbuntuServer' # 'visualstudio' # 'visualstudio2019' # 'SQL2017-WS2016' # 'WindowsServer' # 'servertesting' # 'WindowsServerSemiAnnual' # 'SQL2008R2SP3-WS2008R2SP1' # 'SQL2017-WS2016'
$skus = Get-AzVMImageSku -Location $location -PublisherName $publisherName -Offer $offer

# create a batch pool on the current batch
az batch pool create `
    --id pool001 --vm-size Standard_A1_v2 `
    --target-dedicated-nodes 2 `
    --image canonical:ubuntuserver:18.04-LTS `
    --node-agent-sku-id "batch.node.ubuntu 18.04"


# query the pool
az batch pool show --pool-id pool001 `
    --query "allocationState"


# create a job to run on the pool
az batch job create `
    --id job001 `
    --pool-id pool001

# create tasks on the job
@(1..4) | ForEach {
   az batch task create `
    --task-id task$_ `
    --job-id job001 `
    --command-line "/bin/bash -c 'printenv | grep AZ_BATCH; sleep 90s'"
}

# view task status
az batch task show `
    --job-id job001 `
    --task-id task1

# view task output
az batch task file list `
    --job-id job001 `
    --task-id task1 `
    --output table

# download task file
az batch task file download `
    --job-id job001 `
    --task-id task1 `
    --file-path stdout.txt `
    --destination ./stdout.txt

# delete the batch pool when no longer needed
az batch pool delete --pool-id pool001
