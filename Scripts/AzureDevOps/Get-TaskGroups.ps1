# . .\AzureDevOpsContext.ps1

Function Get-TaskGroups
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'

$taskGroupsUrl = $context.projectBaseUrl + '/distributedtask/taskgroups?api-version=' + $v
Write-Host $taskGroupsUrl

if($context.isOnline) {
    $taskGroups = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $taskGroupsUrl -Method Get
}
else {
    $taskGroups = Invoke-RestMethod -Uri $taskGroupsUrl -UseDefaultCredentials -Method Get
}

return $taskGroups

}