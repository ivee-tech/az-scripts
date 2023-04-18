# . .\AzureDevOpsContext.ps1

# this cmdlet uses the PATCH Build Update REST API which doesn't seem to work properly
# use the Add Build Tag REST API instead:
# https://learn.microsoft.com/en-us/rest/api/azure/devops/build/tags/add-build-tag?view=azure-devops-rest-7.0
Function Set-PatchBuildTags
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][int]$buildId,
    [Parameter(Mandatory=$true)][string[]]$tags,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)


$contentType = 'application/json' # -patch+json'
# PATCH https://dev.azure.com/{organization}/{project}/_apis/build/builds/{buildId}?api-version=7.1-preview.7
$v = $context.apiVersion + '-preview.7'
$buildUrl = $context.projectBaseUrl + '/build/builds/' + $buildId + '?api-version=' + $v
Write-Host $buildUrl

$data = @{ 
    id = $buildId
    tags = $tags 
} | ConvertTo-Json
$data

if($context.isOnline) {
    $build = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $buildUrl -Method Patch -Body $data -ContentType $contentType
}
else {
    $build = Invoke-RestMethod -Uri $buildUrl -UseDefaultCredentials -Method Patch -Body $data -ContentType $contentType
}

return $build

}