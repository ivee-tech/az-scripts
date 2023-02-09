# . .\AzureDevOpsContext.ps1

Function Get-PoolByName
{
    [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$poolName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'

$poolUrl = $context.orgBaseUrl + '/distributedtask/pools?poolName=' + $poolName + '&api-version=' + $v
Write-Host $poolUrl

if($context.isOnline) {
    $pool = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $poolUrl -Method Get
}
else {
    $pool = Invoke-RestMethod -Uri $poolUrl -UseDefaultCredentials -Method Post
}

if($null -ne $pool.value -and $pool.value.length -gt 0) {
    return $pool.value[0]
}
return $null

}
