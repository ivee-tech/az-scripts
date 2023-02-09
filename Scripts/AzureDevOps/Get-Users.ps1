# . .\AzureDevOpsContext.ps1
# . .\Get-AzureDevOpsContext.ps1

Function Get-Users
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'

$graphCtx = Get-AzureDevOpsContext -protocol https -coreServer vssps.dev.azure.com -org $context.org -project $context.project -apiVersion $context.apiVersion `
    -pat $context.pat -isOnline

$usersUrl = $graphCtx.orgBaseUrl + '/graph/users?subjectTypes=msa,aad,svc&api-version=' + $v

Write-Host $usersUrl
if($context.isOnline) {
    $users = Invoke-RestMethod -Headers @{Authorization="Basic $($graphCtx.base64AuthInfo)"} -Uri $usersUrl -Method Get
}
else {
    $users = Invoke-RestMethod -Uri $usersUrl -Method Get -UseDefaultCredentials
}

return $users

}
