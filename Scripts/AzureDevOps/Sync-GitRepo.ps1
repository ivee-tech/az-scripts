Function Sync-GitRepo
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$repoName,
    [Parameter(Mandatory=$true)][string]$customerTenant,
    [Parameter(Mandatory=$true)][string]$srcDir
)

$currentLocation = Get-Location

$dirName = $srcDir # [System.IO.Path]::Combine($srcDir, $customerTenant, $repoName)
$dir = Get-Item $dirName -ErrorAction SilentlyContinue

if($null -eq $dir) {
    Write-Host "Folder $dirName does not exist. You must create the repo and clone it locally first."
    exit
}
else {

    $cmd = 'cd ' + $dirName + '
git rev-parse --is-inside-work-tree'
    $result = Invoke-Expression $cmd
    if($result -ne 'true') {
        Write-Host 'Folder ' $dirName ' is not a GIT repo. You must create the repo and clone it locally first.'
    }
    else {
        $cmd = '
git pull upstream master --allow-unrelated-histories
git pull origin master
        '
        Invoke-Expression $cmd
    }
}

Set-Location $currentLocation

}