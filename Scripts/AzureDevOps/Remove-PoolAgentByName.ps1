# . .\AzureDevOpsContext.ps1

Function Remove-PoolAgentByName
{
    [CmdletBinding()]
param(
    [Parameter()][string]$poolId,
    [Parameter()][string]$poolName,
    [Parameter()][string]$agentName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

if([string]::IsNullOrEmpty($poolId)) {
    $pool = Get-PoolByName -poolName $poolName -context $context
    $poolId = $pool.id
}

$v = $context.apiVersion + '-preview.1'

$agent = Get-PoolAgentByName -poolId $poolId -agentName $agentName -context $context
$agentId = $agent.id

$agentUrl = $context.orgBaseUrl + '/distributedtask/pools/' + $poolId + '/agents/' + $agentId + '?api-version=' + $v
$agentUrl


if($context.isOnline) {
    $result = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $agentUrl -Method Delete
}
else {
    $result = Invoke-RestMethod -Uri $agentUrl -UseDefaultCredentials -Method Delete
}

return $result

}