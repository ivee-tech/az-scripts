# . .\AzureDevOpsContext.ps1

Function Get-PoolAgents
{
    [CmdletBinding()]
param(
    [Parameter()][string]$poolId,
    [Parameter()][string]$poolName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

if([string]::IsNullOrEmpty($poolId)) {
    $pool = Get-PoolByName -poolName $poolName -context $context
    $poolId = $pool.id
}
$v = $context.apiVersion + '-preview.1'

$agentsUrl = $context.orgBaseUrl + '/distributedtask/pools/' + $poolId + '/agents?api-version=' + $v
Write-Host $agentsUrl

if($context.isOnline) {
    $agents = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $agentsUrl -Method Get
}
else {
    $agents = Invoke-RestMethod -Uri $agentsUrl -UseDefaultCredentials -Method Post
}

return $agents

}