param(
    [Parameter(Mandatory=$true)][string]$pat,
    [Parameter(Mandatory=$true)][int]$kvReleaseDefId,
    [Parameter(Mandatory=$true)][int]$kvBuildDefId,
    [Parameter(Mandatory=$true)][int]$kvBuildId,
    [Parameter()][string]$description,
    [Parameter(Mandatory=$true)][string]$resourceGroup,
    [Parameter(Mandatory=$true)][string]$location,
    [Parameter(Mandatory=$true)][string]$keyVaultName,
    [Parameter(Mandatory=$true)][string]$objectId
)

# . .\AzureDevOpsContext.ps1
. .\Get-AzureDevOpsContext.ps1
$context = Get-AzureDevOpsContext -protocol https -coreServer vsrm.dev.azure.com -org daradu -project infrastructure -apiVersion 5.1 `
    -pat $pat -isOnline

. .\Add-DeployKVRelease.ps1

Add-DeployKVRelease -kvReleaseDefId $kvReleaseDefId -kvBuildDefId $kvBuildDefId -kvBuildId $kvBuildId -description $description -context $context `
    -resourceGroup $resourceGroup -location $location -keyVaultName $keyVaultName -objectId $objectId
