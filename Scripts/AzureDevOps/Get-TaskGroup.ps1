# . .\AzureDevOpsContext.ps1
# . .\Get-TaskGroups.ps1

Function Get-TaskGroup
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$taskGroupId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'

$taskGroupUrl = $context.projectBaseUrl + '/distributedtask/taskgroups' + $taskGroupId + '?api-version=' + $v
Write-Host $taskGroupUrl

if($context.isOnline) {
    $taskGroup = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $taskGroupUrl -Method Get
}
else {
    $taskGroup = Invoke-RestMethod -Uri $taskGroupUrl -UseDefaultCredentials -Method Get
}

return $taskGroup

}