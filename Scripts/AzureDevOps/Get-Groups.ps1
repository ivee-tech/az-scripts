# . .\AzureDevOpsContext.ps1
# . .\Get-AzureDevOpsContext.ps1
# . .\Get-ProjectDescriptor.ps1

Function Get-Groups
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$projectName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)


$v = $context.apiVersion + '-preview.1'

$graphCtx = Get-AzureDevOpsContext -protocol https -coreServer vssps.dev.azure.com -org $context.org -project $context.project -apiVersion $context.apiVersion `
    -pat $context.pat -isOnline

$descriptor = Get-ProjectDescriptor -projectName $projectName -context $context
$groupsUrl = $graphCtx.orgBaseUrl + '/graph/groups?scopeDescriptor=' + $descriptor.value + '&api-version=' + $v

Write-Host $groupsUrl
if($context.isOnline) {
    $groups = Invoke-RestMethod -Headers @{Authorization="Basic $($graphCtx.base64AuthInfo)"} -Uri $groupsUrl -Method Get
}
else {
    $groups = Invoke-RestMethod -Uri $groupsUrl -Method Get -UseDefaultCredentials
}

return $groups

}
