# . .\AzureDevOpsContext.ps1

Function Get-UniversalPackage
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$packageName,
    [Parameter(Mandatory=$true)][string]$feedId, # name or ID
    [Parameter(Mandatory=$true)][string]$outputPath,
    [Parameter(Mandatory=$true)][string]$packageVersion, # use semantic version, i.e. 1.0.0
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$currentLocation = Get-Location

Set-Location $env:USERPROFILE

az artifacts universal download --feed $feedId `
    --name $packageName `
    --path $outputPath `
    --version $packageVersion `
    --detect true `
    --organization $context.orgUrl

Set-Location $currentLocation

}


