# . .\AzureDevOpsContext.ps1

Function Remove-BuildTag
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][int]$buildId,
    [Parameter(Mandatory=$true)][string]$tag,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

# PUT https://dev.azure.com/{organization}/{project}/_apis/build/builds/{buildId}/tags/{tag}?api-version=7.0

$contentType = 'application/json'
$buildTagUrl = $context.projectBaseUrl + '/build/builds/' + $buildId + '/tags/' + $tag + '?api-version=' + $context.apiVersion
Write-Host $buildTagUrl

if($context.isOnline) {
    $result = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $buildTagUrl -Method Delete -ContentType $contentType
}
else {
    $result = Invoke-RestMethod -Uri $buildTagUrl -UseDefaultCredentials -Method Delete -ContentType $contentType
}

return $result

}