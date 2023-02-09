# . .\AzureDevOpsContext.ps1
# . .\Get-Group.ps1
# . .\Get-User.ps1

Function Remove-UserEntitlements
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$userName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.3'
$entitlementsCtx = Get-AzureDevOpsContext -protocol https -coreServer vsaex.dev.azure.com -org $context.org -project $context.project -apiVersion $context.apiVersion `
    -pat $context.pat -isOnline

$user = Get-User -userName $userName -context $context
Write-Host $user

$entitlementsUrl = $entitlementsCtx.orgBaseUrl + '/userentitlements/' + $user.originId + '?api-version=' + $v
$entitlementsUrl

if($context.isOnline) {
    $response = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $entitlementsUrl -Method Delete
}
else {
    $response = Invoke-RestMethod -Uri $entitlementsUrl -UseDefaultCredentials -Method Delete
}

return $response

}