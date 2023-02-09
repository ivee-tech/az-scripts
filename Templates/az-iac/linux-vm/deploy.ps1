$resourceGroupName = 'awe'
$filePath = '.\azuredeploy.json'
$paramFilePath = '.\azuredeploy.parameters.json'

$vmName = 'awe-vm-001'
$adminUsername = 'adminUser'
$authenticationType = 'sshPublicKey'
$adminPasswordOrKeyStr = Get-Content $HOME/.ssh/id_rsa.pub
$adminPasswordOrKey = ConvertTo-SecureString -String $adminPasswordOrKeyStr -AsPlainText -Force
$dnsLabelPrefix = $vmName
$offer = 'UbuntuServer'
$ubuntuOSVersion = '18.04-LTS'
$vmSize = 'Standard_B2ms'
$vnetName = 'awe-vnet'
$subnetName = 'default'
# $src = Get-Content './scripts/install.sh'
# $bytes = [System.Text.Encoding]::UTF8.GetBytes($src)
# $script = [System.Convert]::ToBase64String($bytes)

New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName `
  -TemplateFile $filePath -TemplateParameterFile $paramFilePath -Mode Incremental `
  -vmName $vmName -adminUsername $adminUsername -authenticationType $authenticationType -adminPasswordOrKey $adminPasswordOrKey `
  -dnsLabelPrefix $dnsLabelPrefix -offer $offer -ubuntuOSVersion $ubuntuOSVersion `
  -vmSize $vmSize -vnetName $vnetName -subnetName $subnetName `
#  -script $script

# find skus
$location = 'AustraliaCentral'
$publisherName = 'Canonical' # 'MicrosoftWindowsServer' # 'MicrosoftVisualStudio' # 'MicrosoftWindowsServer' # 'MicrosoftWindowsDesktop' # 'cloudera' # 'RedHat' # 'atomicorp' # 'MicrosoftVisualStudio' # 'MicrosoftVisualStudio' # 'MicrosoftSqlServer' # 'MicrosoftWindowsServer' # 'MicrosoftSqlServer'
$offers = Get-AzVMImageOffer -Location $location -PublisherName $publisherName

$offer = 'UbuntuServer' # 'UbuntuServer' # 'Ubuntu_Core' # 'WindowsServerSemiAnnual' # 'WindowsServer' # 'sql2019-ws2019' # 'windows-10' #'cloudera-centos-os' # 'RHEL' # 'secure-os' # 'visualstudio2019latest' # 'SQL2017-WS2016' # 'visualstudio2019latest' # 'UbuntuServer' # 'visualstudio' # 'visualstudio2019' # 'SQL2017-WS2016' # 'WindowsServer' # 'servertesting' # 'WindowsServerSemiAnnual' # 'SQL2008R2SP3-WS2008R2SP1' # 'SQL2017-WS2016'
$skus = Get-AzVMImageSku -Location $location -PublisherName $publisherName -Offer $offer
$skus

  