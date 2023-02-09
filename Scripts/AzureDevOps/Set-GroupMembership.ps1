﻿# . .\AzureDevOpsContext.ps1
# . .\Get-Group.ps1

Function Set-GroupMembership
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$projectName,
    [Parameter(Mandatory=$true)][string]$groupName,
    [Parameter(Mandatory=$true)][string]$containerName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'
$graphCtx = Get-AzureDevOpsContext -protocol https -coreServer vssps.dev.azure.com -org $context.org -project $context.project -apiVersion $context.apiVersion `
    -pat $context.pat -isOnline

$group = Get-Group -projectName $projectName -groupName $groupName -context $context
Write-Host $group
$container = Get-Group -projectName $projectName -groupName $containerName -context $context
Write-Host $container

$membershipUrl = $graphCtx.orgBaseUrl + '/graph/memberships/' + $group.descriptor + '/' + $container.descriptor + '?api-version=' + $v
$membershipUrl

if($context.isOnline) {
    $response = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $membershipUrl -Method Put
}
else {
    $response = Invoke-RestMethod -Uri $membershipUrl -UseDefaultCredentials -Method Put
}

return $response

}