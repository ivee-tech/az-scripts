# . .\AzureDevOpsContext.ps1

Function Get-Leases
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter()][int]$definitionId = 0,
    [Parameter()][string]$ownerId = '',
    [Parameter()][int]$runId = 0,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

# GET https://dev.azure.com/{organization}/{project}/_apis/build/retention/leases?api-version=7.0
$leasesUrl = $context.projectBaseUrl + '/build/retention/leases?api-version=' + $context.apiVersion
if($definitionId -gt 0) {
    $leasesUrl += '&definitionId=' + $definitionId
}
if(![string]::IsNullOrEmpty($ownerId)) {
    $leasesUrl += '&ownerId=' + $ownerId
}
if($runId -gt 0) {
    $leasesUrl += '&runId=' + $runId
}
Write-Host $leasesUrl

if($context.isOnline) {
    $result = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $leasesUrl -Method Get
}
else {
    $result = Invoke-RestMethod -Uri $leasesUrl -UseDefaultCredentials -Method Get
}
return $result

}