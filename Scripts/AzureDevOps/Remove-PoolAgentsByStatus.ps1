Function Remove-PoolAgentsByStatus {

param(
    [ValidateNotNullOrEmpty()]
    [Parameter()][string]$poolId,
    [Parameter()][string]$poolName,
    [ValidateSet("online", "offline")]
    [Parameter(Mandatory=$true)][string]$status,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

if([string]::IsNullOrEmpty($poolId)) {
    $pool = Get-PoolByName -poolName $poolName -context $context
    $poolId = $pool.id
}

$v = $context.apiVersion + '-preview.1'
$agentsUrl = $context.orgBaseUrl + '/distributedtask/pools/' + $poolId + '/agents/?api-version=' + $v
$agentsUrl


if($isOnline) {
    $agents = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $agentsUrl
}
else {
    $agents = Invoke-RestMethod -Uri $agentsUrl -UseDefaultCredentials
}

$agents.value | ForEach-Object {

if($_.status -eq $status) {

    $agentId = $_.id

    $agentUrl = $context.orgBaseUrl + '/distributedtask/pools/' + $poolId + '/agents/' + $agentId + '?api-version=' + $v
    $agentUrl


    if($context.isOnline) {
        $result = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $agentUrl -Method Delete
    }
    else {
        $result = Invoke-RestMethod -Uri $agentUrl -UseDefaultCredentials -Method Delete
    }

    $result

}

}

}