# . .\AzureDevOpsContext.ps1

Function Add-Field
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$name,
    [Parameter()][string]$description,
    [ValidateSet(
        'boolean',	
        'dateTime',	
        'double',
        'guid',	
        'history',	
        'html',	
        'identity',	
        'integer',	
        'picklistDouble',	
        'picklistInteger',	
        'picklistString',	
        'plainText',	
        'string',	
        'treePath'
    )]
    [Parameter(Mandatory=$true)][string]$type,
    [Parameter()][switch]$isIdentity,
    [Parameter()][switch]$isPicklist,
    [Parameter()][switch]$isQueryable,
    [Parameter()][string]$picklistId,
    [Parameter()][switch]$readOnly,
    [Parameter()][switch]$canSortBy,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

# POST https://dev.azure.com/{organization}/{project}/_apis/wit/fields?api-version=6.1-preview.2

$v = $context.apiVersion + '-preview.2'
$fieldsUrl = $context.projectBaseUrl + '/wit/fields?api-version=' + $v
$fieldsUrl

$data = @{
    name = $name
    description = $description
    type = $type
    referenceName = "Custom.$($name)"
    usage = "workItem"
}
if($isIdentity) { $data.isIdentity = $true }
if($isPicklist) { 
    $data.isPicklist = $true 
    $data.picklistId = $picklistId
}
if($isQueryable) { $data.isQueryable = $true }
if($canSortBy) { $data.canSortBy = $true }
if($readOnly) { $data.readOnly = $true }

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
