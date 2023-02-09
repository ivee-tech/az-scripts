# . .\AzureDevOpsContext.ps1

Function Add-AspNetCoreGitRepoStructure
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$repoName,
    [Parameter(Mandatory=$true)][string]$appName,
    [Parameter(Mandatory=$true)][string]$srcDir,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$currentLocation = Get-Location

$projectGitUrl = $context.projectUrl + '/_git/'
$repoUrl = $projectGitUrl + $repoName

$dirName = $srcDir # [System.IO.Path]::Combine($rootFolder, $customerTenant, $repoName)
$dir = Get-Item $dirName -ErrorAction SilentlyContinue

if($null -ne $dir) {
    Write-Host 'Folder ' $dirName ' already exists.'
}
else {
    $cmd = '
md ' + $dirName
    Invoke-Expression $cmd

    Copy-Item -Path '../.gitignore' -Destination $dirName
    Copy-Item -Path '../readme.md' -Destination $dirName

    $cmd = '
cd ' + $dirName + '
git init
'
    Invoke-Expression $cmd

    $cmd = '
git add .
git commit -m "Initial commit"
git remote add origin ' + $repoUrl + '
dotnet new webapp --name ' + $appName + '
git add .
git commit -m "Added webapp"
git push origin master
'

    Invoke-Expression $cmd


}

Set-Location $currentLocation

}


