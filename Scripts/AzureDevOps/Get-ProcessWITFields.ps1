# . .\AzureDevOpsContext.ps1

Function Get-ProcessWITFields
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$processId,
    [Parameter(Mandatory=$true)][string]$witRefName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

# GET https://dev.azure.com/{organization}/_apis/work/processes/{processId}/workItemTypes/{witRefName}/fields?api-version=6.1-preview.2
$v = $context.apiVersion + '-preview.2'
$fieldsUrl = $context.orgBaseUrl + '/work/processes/' + $processId + '/workItemTypes/' + $witRefName + '/fields?api-version=' + $v
$fieldsUrl

if($context.isOnline) {
    $fields = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $fieldsUrl -Method Get
}
else {
    $fields = Invoke-RestMethod -Uri $fieldsUrl -UseDefaultCredentials -Method Get
}

return $fields

}