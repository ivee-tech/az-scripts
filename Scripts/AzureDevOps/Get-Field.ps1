# . .\AzureDevOpsContext.ps1

Function Get-Field
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$fieldNameOrRefName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

# GET https://dev.azure.com/{organization}/{project}/_apis/wit/fields/{fieldNameOrRefName}?api-version=6.0

$fieldUrl = $context.projectBaseUrl + '/wit/fields/' + $fieldNameOrRefName + '?api-version=' + $context.apiVersion
$fieldUrl

if($context.isOnline) {
    $field = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $fieldUrl -Method Get
}
else {
    $field = Invoke-RestMethod -Uri $fieldUrl -UseDefaultCredentials -Method Get
}

return $field

}