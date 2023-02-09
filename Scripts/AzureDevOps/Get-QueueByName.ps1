# . .\AzureDevOpsContext.ps1

Function Get-QueueByName
{
    [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$queueName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'

$queuesUrl = $context.projectBaseUrl + '/distributedtask/queues?queueName=' + $queueName + '&api-version=' + $v
Write-Host $queuesUrl

if($context.isOnline) {
    $queues = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $queuesUrl -Method Get
}
else {
    $queues = Invoke-RestMethod -Uri $queuesUrl -UseDefaultCredentials -Method Post
}

if($null -ne $queues.value -and $queues.value.length -gt 0) {
    return $queues.value[0]
}
return $null

}
