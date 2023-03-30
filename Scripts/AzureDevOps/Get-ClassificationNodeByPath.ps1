# . .\AzureDevOpsContext.ps1

Function Get-ClassificationNodeByPath
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [ValidateSet('areas', 'iterations')]
    [Parameter(Mandatory=$true)][string]$structureGroup,
    [Parameter()][string]$path,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

# GET https://dev.azure.com/{organization}/{project}/_apis/wit/classificationnodes/{structureGroup}/{path}?api-version=7.1-preview.2
$v = $context.apiVersion + '-preview.2'
$classificationNodeUrl = $context.orgUrl + '/' + $context.project + '/_apis/wit/classificationnodes/' + $structureGroup + '/' + $path + '?api-version=' + $v
Write-Host $classificationNodeUrl

if($context.isOnline) {
    $buildDef = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $classificationNodeUrl -Method Get
}
else {
    $buildDef = Invoke-RestMethod -Uri $classificationNodeUrl -UseDefaultCredentials -Method Post
}

return $buildDef

}