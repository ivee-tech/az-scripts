# . .\AzureDevOpsContext.ps1

Function Get-Lease
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][int]$leaseId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

# GET https://dev.azure.com/{organization}/{project}/_apis/build/retention/leases?/{leaseId}api-version=7.0
$leasesUrl = $context.projectBaseUrl + '/build/retention/leases/' + $leaseId + '?api-version=' + $context.apiVersion
Write-Host $leasesUrl

if($context.isOnline) {
    $result = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $leasesUrl -Method Get
}
else {
    $result = Invoke-RestMethod -Uri $leasesUrl -UseDefaultCredentials -Method Get
}
return $result

}