# . .\AzureDevOpsContext.ps1

class BoardColumn {
    [ValidateSet('inProgress', 'incoming', 'outgoing')]
    [string]$columnType
    [string]$id	
    [bool]$isSplit	
    [int]$itemLimit	
    [string]$name	
    [hashtable]$stateMappings # keys are the WIT names, values are the states
}

# example
<#
{
    "id": "12eed5fb-8af3-47bb-9d2a-058fbe7e1196",
    "name": "New",
    "itemLimit": 0,
    "stateMappings": {
      "Product Backlog Item": "New",
      "Bug": "New"
    }
}
#>


Function Set-BoardColumns
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$teamName, # name or ID
    [Parameter(Mandatory=$true)][string]$boardName, # name or ID
    # array of BoardColumn objects, see the definition: https://learn.microsoft.com/en-us/rest/api/azure/devops/work/columns/update?view=azure-devops-rest-7.0&tabs=HTTP#boardcolumn
    # [Parameter(Mandatory=$true)][BoardColumn[]]$columns, 
    [Parameter(Mandatory=$true)][hashtable[]]$columns, 
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'

# PUT https://dev.azure.com/{organization}/{project}/{team}/_apis/work/boards/{board}/columns?api-version=7.0
$v = $context.apiVersion
$boardUrl = $context.orgUrl + '/' + $context.project + '/' + $teamName + '/_apis/work/boards/' + $boardName + '/columns?api-version=' + $v
Write-Host $boardUrl

$data = $columns | ConvertTo-Json

if($context.isOnline) {
    $board = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $boardUrl -Method Put -Body $data -ContentType $contentType
}
else {
    $board = Invoke-RestMethod -Uri $boardUrl -UseDefaultCredentials -Method Put -Body $data -ContentType $contentType
}

return $board

}