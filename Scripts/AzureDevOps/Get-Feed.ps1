# . .\AzureDevOpsContext.ps1

Function Get-Feed
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$feedId,
    [Parameter()][switch]$orgLevel,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'
if($orgLevel) {
    $feedUrl = $context.orgBaseUrl + '/packaging/feeds/' + $feedId + '?api-version=' + $v
}
else {
    $feedUrl = $context.projectBaseUrl + '/packaging/feeds/' + $feedId + '?api-version=' + $v
}
Write-Host $feedUrl

if($context.isOnline) {
    $feed = Invoke-WebRequest -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $feedUrl -Method Get
}
else {
    $feed = Invoke-WebRequest -Uri $feedUrl -UseDefaultCredentials -Method Get
}
return $feed.Content | ConvertFrom-Json

}