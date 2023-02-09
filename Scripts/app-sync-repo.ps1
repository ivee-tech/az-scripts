param(
    [Parameter(Mandatory=$true)][string]$customerTenant,
    [Parameter(Mandatory=$true)][string]$repoName,
    [Parameter(Mandatory=$true)][string]$srcDir
)

. .\Sync-GitRepo.ps1
Sync-GitRepo -repoName $repoName `
    -customerTenant $customerTenant -srcDir $srcDir
