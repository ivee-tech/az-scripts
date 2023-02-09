# . .\AzureDevOpsContext.ps1

Function Add-UniversalPackage
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$packageName,
    [Parameter()][string]$packageDescription,
    [Parameter(Mandatory=$true)][string]$feedId, # name or ID
    [Parameter(Mandatory=$true)][string]$packagePath,
    [Parameter(Mandatory=$true)][string]$packageVersion, # use semantic version, i.e. 1.0.0
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$currentLocation = Get-Location

Set-Location $env:USERPROFILE

az artifacts universal publish --feed $feedId `
    --name $packageName `
    --path $packagePath `
    --version $packageVersion `
    --description "$packageDescription" `
    --detect true `
    --organization $context.orgUrl

Set-Location $currentLocation

}


