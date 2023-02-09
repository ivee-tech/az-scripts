# . .\AzureDevOpsContext.ps1

Function Add-YamlPipeline
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$name,
    [Parameter(Mandatory=$true)][string]$description,
    [Parameter(Mandatory=$true)][string]$repoName,
    [Parameter(Mandatory=$true)][string]$yamlPath,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$currentLocation = Get-Location

Set-Location $env:USERPROFILE

$repoUrl = $context.protocol + '://' + $context.org + '@' + $context.coreServer + '/' + $context.org + '/' + $context.project + '/_git/' + $repoName
$repoUrl

az pipelines create `
    --name $name `
    --description $description `
    --repository $repoUrl `
    --branch master `
    --yml-path $yamlPath `
    --repository-type tfsgit `
    --organization $context.orgUrl `
    --project $context.project `
    --detect true

Set-Location $currentLocation

}


