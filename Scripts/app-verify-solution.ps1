param(
    [Parameter(Mandatory=$true)][string]$customerTenant,
    [Parameter(Mandatory=$true)][string]$repoName,
    [Parameter(Mandatory=$true)][string]$srcDir
)

. .\Test-GitVSSolution.ps1
Test-GitVSSolution -repoName $repoName -customerTenant $customerTenant -srcDir $srcDir
