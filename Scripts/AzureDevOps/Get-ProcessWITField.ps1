# . .\AzureDevOpsContext.ps1

Function Get-ProcessWITField
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$processId,
    [Parameter(Mandatory=$true)][string]$witRefName,
    [Parameter(Mandatory=$true)][string]$fieldRefName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

# GET https://dev.azure.com/{organization}/_apis/work/processes/{processId}/workItemTypes/{witRefName}/fields/{fieldRefName}?api-version=6.1-preview.2
$v = $context.apiVersion + '-preview.2'
$fieldUrl = $context.orgBaseUrl + '/work/processes/' + $processId + '/workItemTypes/' + $witRefName + '/fields/' + $fieldRefName + '?api-version=' + $v
$fieldUrl

if($context.isOnline) {
    $field = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $fieldUrl -Method Get
}
else {
    $field = Invoke-RestMethod -Uri $fieldUrl -UseDefaultCredentials -Method Get
}

return $field

}