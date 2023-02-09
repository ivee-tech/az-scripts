# . .\AzureDevOpsContext.ps1

Function Add-ProcessWITField
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$processId,
    [Parameter(Mandatory=$true)][string]$witRefName,
    [Parameter(Mandatory=$true)][string]$referenceName,
    [Parameter()][string[]]$allowedValues,
    [Parameter()][string]$defaultValue,
    [Parameter()][switch]$required,
    [Parameter()][switch]$readOnly,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

# POST https://dev.azure.com/{organization}/_apis/work/processes/{processId}/workItemTypes/{witRefName}/fields?api-version=6.1-preview.2

$v = $context.apiVersion + '-preview.2'
$fieldsUrl = $context.orgBaseUrl + '/work/processes/' + $processId + '/workItemTypes/' + $witRefName + '/fields?api-version=' + $v
$fieldsUrl

$data = @{
    referenceName = $referenceName
}
if($required) { $data.required = $true }
if($readOnly) { $data.readOnly = $true }
if(![string]::IsNullOrEmpty($defaultValue)) { $data.defaultValue = $defaultValue }
if($allowedValues.Count -gt 0) { $data.allowedValues = $allowedValues }

$contentType = 'application/json'
$body = $data | ConvertTo-Json -Depth 10

if($context.isOnline) {
    $field = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $fieldsUrl -Method Post -Body $body -ContentType $contentType
}
else {
    $field = Invoke-RestMethod -Uri $fieldsUrl -UseDefaultCredentials -Method Post -Body $body -ContentType $contentType
}

return $field

}
