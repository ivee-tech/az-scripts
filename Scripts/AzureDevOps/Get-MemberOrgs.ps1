# NOT WORKING WITH THE CONTEXT
# . .\AzureDevOpsContext.ps1

Function Get-MemberOrgs
{
param(
    [ValidateNotNullOrEmpty()]
    # use the following link to get own profile info: https://app.vssps.visualstudio.com/_apis/profile/profiles/me?api-version=5.1
    [Parameter(Mandatory=$true)][string]$memberId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$accountsUrl = 'https://app.vssps.visualstudio.com/_apis/accounts?memberId=' + $memberId + '&api-version=' + $context.apiVersion
Write-Host $accountsUrl

if($context.isOnline) {
    $accounts = Invoke-WebRequest -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $accountsUrl -Method Get
}
else {
    $accounts = Invoke-WebRequest -Uri $accountsUrl -UseDefaultCredentials -Method Get
}
return $accounts

}
