param(
    [Parameter(Mandatory=$true)][string]$project,
    [Parameter(Mandatory=$true)][string]$pat,
    [Parameter(Mandatory=$true)][string]$customerTenant,
    [Parameter(Mandatory=$true)][string]$repoName,
    [Parameter(Mandatory=$true)][string]$srcDir
)

# . .\AzureDevOpsContext.ps1
. .\Get-AzureDevOpsContext.ps1
$context = Get-AzureDevOpsContext -protocol https -coreServer dev.azure.com -org ivee -project $project -apiVersion 5.1 `
    -pat $pat -isOnline

. .\Add-GitRepo.ps1
Add-GitRepo -repoName $repoName -context $context

. .\Add-GitRepoStructure.ps1
Add-GitRepoStructure -repoName $repoName -upstreamRepoUrl https://daradu@dev.azure.com/daradu/infrastructure/_git/app `
    -customerTenant $customerTenant -srcDir $srcDir -context $context
