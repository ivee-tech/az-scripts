Function Invoke-CloneRepo
{
    [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]
    $pat,
    [Parameter(Mandatory=$true)]
    [string]
    $repoUrl,
    [Parameter(Mandatory=$true)]
    [string]
    $localDir
)

$encodedPat = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(':' + $pat))

$cmd = 'git -c http.' + $repoUrl + '.extraheader="AUTHORIZATION:Basic ' + $encodedPat + '" clone ' + $repoUrl + ' --no-checkout --branch master "' + $localDir + '"'

Write-Host $repoUrl
Write-Host $cmd

cmd.exe /c $cmd

}

