# . .\AzureDevOpsContext.ps1

Function Set-FeedRetentionPolicy
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$feedId,
    [Parameter()][switch]$orgLevel,
    [Parameter(Mandatory=$true)][int]$countLimit,
    [Parameter(Mandatory=$true)][int]$daysToKeepRecentlyDownloadedPackages,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'
$v = $context.apiVersion + '-preview.1'

if($orgLevel) {
    $retentionPolicyUrl = $context.orgBaseUrl + '/packaging/Feeds/' + $feedId + '/retentionpolicies?api-version=' + $v
}
else {
    $retentionPolicyUrl = $context.projectBaseUrl + '/packaging/Feeds/' + $feedId + '/retentionpolicies?api-version=' + $v
}
$retentionPolicyUrl


$data = @{
    countLimit = $countLimit;
    daysToKeepRecentlyDownloadedPackages = $daysToKeepRecentlyDownloadedPackages;

} | ConvertTo-Json -Depth 10

if($context.isOnline) {
    $retentionPolicy = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $retentionPolicyUrl -Method Put -Body $data -ContentType $contentType
}
else {
    $retentionPolicy = Invoke-RestMethod -Uri $retentionPolicyUrl -UseDefaultCredentials -Method Put -Body $data -ContentType $contentType
}

return $retentionPolicy

}