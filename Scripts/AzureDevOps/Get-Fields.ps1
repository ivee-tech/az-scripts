# . .\AzureDevOpsContext.ps1

Function Get-Fields
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

# GET https://dev.azure.com/{organization}/{project}/_apis/wit/fields?api-version=6.0

$fieldsUrl = $context.projectBaseUrl + '/wit/fields?api-version=' + $context.apiVersion
$fieldsUrl

if($context.isOnline) {
    $fields = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $fieldsUrl -Method Get
}
else {
    $fields = Invoke-RestMethod -Uri $fieldsUrl -UseDefaultCredentials -Method Get
}

return $fields

}