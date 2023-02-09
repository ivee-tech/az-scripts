# . .\AzureDevOpsContext.ps1

Function Add-GroupAzDevOpsCli
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$name,
    [Parameter(Mandatory=$true)][string]$description,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$currentLocation = Get-Location

Set-Location $env:USERPROFILE

az devops security group create --project "$($context.project)" --name "$name" --description "$description"

Set-Location $currentLocation

}


