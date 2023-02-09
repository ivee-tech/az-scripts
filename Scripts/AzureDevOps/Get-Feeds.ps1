# . .\AzureDevOpsContext.ps1

Function Get-Feeds
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter()][switch]$orgLevel,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'
if($orgLevel) {
    $feedsUrl = $context.orgBaseUrl + '/packaging/feeds?api-version=' + $v
}
else {
    $feedsUrl = $context.projectBaseUrl + '/packaging/feeds?api-version=' + $v
}
Write-Host $feedsUrl

if($context.isOnline) {
    $feeds = Invoke-WebRequest -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $feedsUrl -Method Get
}
else {
    $feeds = Invoke-WebRequest -Uri $feedsUrl -UseDefaultCredentials -Method Get
}
return $feeds.Content | ConvertFrom-Json

}