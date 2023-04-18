# . .\AzureDevOpsContext.ps1

Function Add-BuildTags
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][int]$buildId,
    [Parameter(Mandatory=$true)][string[]]$tags,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

# POST https://dev.azure.com/{organization}/{project}/_apis/build/builds/{buildId}/tags?api-version=7.0

$contentType = 'application/json'
$buildTagUrl = $context.projectBaseUrl + '/build/builds/' + $buildId + '/tags?api-version=' + $context.apiVersion
Write-Host $buildTagUrl

$data = ConvertTo-Json -InputObject $tags
$data

if($context.isOnline) {
    $result = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $buildTagUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $result = Invoke-RestMethod -Uri $buildTagUrl -UseDefaultCredentials -Method Post -Body $data -ContentType $contentType
}

return $result

}