# . .\AzureDevOpsContext.ps1

Function Remove-Leases
{
    [CmdletBinding()]
param(
    # comma-separated list of Lease IDs
    [Parameter()][string]$leaseIds,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

# DELETE https://dev.azure.com/{organization}/{project}/_apis/build/retention/leases?ids={ids}&api-version=7.0
$leasesUrl = $context.projectBaseUrl + '/build/retention/leases?ids=' + $leaseIds + '&api-version=' + $context.apiVersion
Write-Host $leasesUrl

if($context.isOnline) {
    $result = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $leasesUrl -Method Delete
}
else {
    $result = Invoke-RestMethod -Uri $leasesUrl -UseDefaultCredentials -Method Delete
}

return $result

}