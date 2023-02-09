# . .\AzureDevOpsContext.ps1

Function Add-TaskGroup
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][PSCustomObject]$taskGroup,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'
$v = $context.apiVersion + '-preview.1'

$taskGroupsUrl = $context.projectBaseUrl + '/distributedtask/taskgroups?api-version=' + $v
$taskGroupsUrl

$data = ConvertTo-Json -InputObject $taskGroup -Depth 10

if($context.isOnline) {
    $taskGroup = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $taskGroupsUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $taskGroup = Invoke-RestMethod -Uri $taskGroupsUrl -UseDefaultCredentials -Method Post -Body $data -ContentType $contentType
}

return $taskGroup

}