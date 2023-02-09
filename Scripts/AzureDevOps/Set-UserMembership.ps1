# . .\AzureDevOpsContext.ps1
# . .\Get-Group.ps1
# . .\Get-User.ps1

Function Set-UserMembership
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$projectName,
    [Parameter(Mandatory=$true)][string]$userName,
    [Parameter(Mandatory=$true)][string]$containerName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'
$graphCtx = Get-AzureDevOpsContext -protocol https -coreServer vssps.dev.azure.com -org $context.org -project $context.project -apiVersion $context.apiVersion `
    -pat $context.pat -isOnline

$user = Get-User -userName $userName -context $context
Write-Host $user
if ($null -eq $user) {
    throw "User $userName doesn't exist."
}
$container = Get-Group -projectName $projectName -groupName $containerName -context $context
if ($null -eq $container) {
    throw "Group $containerName doesn't exist."
}
Write-Host $container

$membershipUrl = $graphCtx.orgBaseUrl + '/graph/memberships/' + $user.descriptor + '/' + $container.descriptor + '?api-version=' + $v
$membershipUrl

if($context.isOnline) {
    $response = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $membershipUrl -Method Put
}
else {
    $response = Invoke-RestMethod -Uri $membershipUrl -UseDefaultCredentials -Method Put
}

return $response

}