param(
    [Parameter(Mandatory=$true)][string]$customerTenant,
    [Parameter(Mandatory=$true)][string]$repoName,
    [Parameter(Mandatory=$true)][string]$srcDir,
    [Parameter(Mandatory=$true)][string]$commitMessage
)

. .\Push-GitChanges.ps1
Push-GitChanges -repoName $repoName -customerTenant $customerTenant -srcDir $srcDir `
    -commitMessage $commitMessage
