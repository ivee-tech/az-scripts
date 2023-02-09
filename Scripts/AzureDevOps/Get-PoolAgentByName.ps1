# . .\AzureDevOpsContext.ps1

Function Get-PoolAgentByName
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

$agentsUrl = $context.orgBaseUrl + '/distributedtask/pools/' + $poolId + '/agents?agentName=' + $agentName + '&api-version=' + $v
Write-Host $agentsUrl

if($context.isOnline) {
    $agents = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $agentsUrl -Method Get
}
else {
    $agents = Invoke-RestMethod -Uri $agentsUrl -UseDefaultCredentials -Method Post
}

if($null -ne $agents.value -and $agents.value.length -gt 0) {
    return $agents.value[0]
}
return $null

}