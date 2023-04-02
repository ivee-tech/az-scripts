# . .\AzureDevOpsContext.ps1

Function Get-BoardColumns
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$teamName, # name or ID
    [Parameter(Mandatory=$true)][string]$boardName, # name or ID
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

# GET https://dev.azure.com/{organization}/{project}/{team}/_apis/work/boards/{board}/columns?api-version=7.0
$v = $context.apiVersion
$boardUrl = $context.orgUrl + '/' + $context.project + '/' + $teamName + '/_apis/work/boards/' + $boardName + '/columns?api-version=' + $v
Write-Host $boardUrl

if($context.isOnline) {
    $boardColumns = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $boardUrl
}
else {
    $boardColumns = Invoke-RestMethod -Uri $boardUrl -UseDefaultCredentials
}

return $boardColumns

}