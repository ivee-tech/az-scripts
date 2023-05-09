# . .\AzureDevOpsContext.ps1

Function Get-BuildLeases
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][int]$buildId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

# GET https://dev.azure.com/{organization}/{project}/_apis/build/builds/{buildId}/leases?api-version=7.0
$buildLeasesUrl = $context.projectBaseUrl + '/build/builds/' + $buildId + '/leases?api-version=' + $context.apiVersion
Write-Host $buildLeasesUrl

if($context.isOnline) {
    $buildLeases = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $buildLeasesUrl -Method Get
}
else {
    $buildLeases = Invoke-RestMethod -Uri $buildLeasesUrl -UseDefaultCredentials -Method Post
}

return $buildLeases

}