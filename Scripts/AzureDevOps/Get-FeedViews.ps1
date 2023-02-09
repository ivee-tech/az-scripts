# . .\AzureDevOpsContext.ps1

Function Get-FeedViews
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$feedId,
    [Parameter()][switch]$orgLevel,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'
if($orgLevel) {
    $feedViewsUrl = $context.orgBaseUrl + '/packaging/feeds/' + $feedId + '?api-version=' + $v
}
else {
    $feedViewsUrl = $context.projectBaseUrl + '/packaging/feeds/' + $feedId + '?api-version=' + $v
}
Write-Host $feedViewsUrl

if($context.isOnline) {
    $feedViews = Invoke-WebRequest -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $feedViewsUrl -Method Get
}
else {
    $feedViews = Invoke-WebRequest -Uri $feedViewsUrl -UseDefaultCredentials -Method Get
}
return $feedViews

}