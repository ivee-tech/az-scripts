# . .\AzureDevOpsContext.ps1

Function Get-GroupAvatar
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$projectName,
    [Parameter(Mandatory=$true)][string]$groupName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'

$graphCtx = Get-AzureDevOpsContext -protocol https -coreServer vssps.dev.azure.com -org $context.org -project $context.project -apiVersion $context.apiVersion `
    -pat $context.pat -isOnline
$v = $context.apiVersion + '-preview.1'
$group = Get-Group -projectName $projectName -groupName $groupName -context $context

$avatarUrl = $graphCtx.orgBaseUrl + '/graph/Subjects/' + $group.descriptor + '/avatars?api-version=' + $v
Write-Host $avatarUrl

if($context.isOnline) {
    $avatar = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $avatarUrl
}
else {
    $avatar = Invoke-RestMethod -Uri $avatarUrl -UseDefaultCredentials
}

return $avatar

}