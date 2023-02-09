# . .\AzureDevOpsContext.ps1

Function Import-TaskGroup
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$jsonDefFilePath,
    [Parameter(Mandatory=$true)][string]$taskGroupName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$json = Get-Content -Path $jsonDefFilePath -Raw
$taskGroupDef = ConvertFrom-Json -InputObject $json
$taskGroupDef.name = $taskGroupName
$taskGroupDef.friendlyName = $taskGroupName

$contentType = 'application/json'
$v = $context.apiVersion + '-preview.1'

$taskGroupUrl = $context.projectBaseUrl + '/distributedtask/taskgroups?api-version=' + $v
Write-Host $taskGroupUrl

$data = ConvertTo-Json -InputObject $taskGroupDef -Depth 100

if($context.isOnline) {
    $newTaskGroup = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $taskGroupUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $newTaskGroup = Invoke-RestMethod -Uri $taskGroupUrl -UseDefaultCredentials -Method Post -Body $data -ContentType $contentType
}

return $newTaskGroup

}