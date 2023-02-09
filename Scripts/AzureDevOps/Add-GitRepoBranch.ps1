# . .\AzureDevOpsContext.ps1

Function Add-GitRepoBranch
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$repoName,
    [Parameter(Mandatory=$true)][string]$srcDir,
    [Parameter(Mandatory=$true)][string]$folderName,
    [Parameter(Mandatory=$true)][string]$branchName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$currentLocation = Get-Location

$projectGitUrl = $context.projectUrl + '/_git/'
$repoUrl = $projectGitUrl + $repoName

$dirName = [System.IO.Path]::Combine($srcDir, $folderName, $branchName)
$dir = Get-Item $dirName -ErrorAction SilentlyContinue

if($null -ne $dir) {
    Write-Host 'Folder ' $dirName ' already exists.'
}
else {
    $cmd = '
md ' + $dirName
    Invoke-Expression $cmd

    $cmd = '
cd ' + $dirName + '
git clone ' + $repoUrl + ' ' + $dirName + '
git checkout -b ' + $folderName + '/' + $branchName + '
'
    Invoke-Expression $cmd

    $cmd = '
git add .
git commit -m "New branch commit"
git push origin ' + $folderName + '/' + $branchName + '
'

    Invoke-Expression $cmd


}

Set-Location $currentLocation

}
