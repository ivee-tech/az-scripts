# . .\AzureDevOpsContext.ps1

# It works only with collections migrated using the Azure DevOps migrator (high-fidelity)
Function Import-ProcessTemplate
{
param(
    [Parameter(Mandatory=$true)][string]$zipFilePath,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)
$contentType = 'application/octet-stream'

$v = $context.apiVersion + '-preview.1';
$content = [System.IO.File]::ReadAllBytes($zipFilePath)

$importProcessUrl = $context.orgBaseUrl + '/work/processadmin/processes/import?api-version=' + $v
Write-Host $importProcessUrl

if($context.isOnline) {
    $importResult = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $importProcessUrl -Method Post -Body $content -ContentType $contentType
}
else {
    $importResult = Invoke-RestMethod -Uri $importProcessUrl -UseDefaultCredentials -Method Post -Body $content -ContentType $contentType
}

return $importResult;
}