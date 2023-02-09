# . .\AzureDevOpsContext.ps1

Function Get-ProcessWITs
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$processId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

# GET https://dev.azure.com/{organization}/_apis/work/processes/{processId}/workitemtypes?api-version=6.1-preview.2
$v = $context.apiVersion + '-preview.2'
$witsUrl = $context.orgBaseUrl + '/work/processes/' + $processId + '/workItemTypes?api-version=' + $v
$witsUrl

if($context.isOnline) {
    $wits = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $witsUrl -Method Get
}
else {
    $wits = Invoke-RestMethod -Uri $witsUrl -UseDefaultCredentials -Method Get
}

return $wits

}