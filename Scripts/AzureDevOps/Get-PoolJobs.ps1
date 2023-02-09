# . .\AzureDevOpsContext.ps1

Function Get-PoolJobs
{
    [CmdletBinding()]
param(
    [Parameter()][string]$poolId,
    [Parameter()][string]$poolName,
    [ValidateSet("", "succeeded", "failed", "canceled")] # use "" for running jobs
    [string]$result,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

if([string]::IsNullOrEmpty($poolId)) {
    $pool = Get-PoolByName -poolName $poolName -context $context
    $poolId = $pool.id
}

$jobsUrl = $context.orgBaseUrl + '/distributedtask/pools/' + $poolId + '/jobrequests?api-version=' + $context.apiVersion
Write-Host $jobsUrl

if($context.isOnline) {
    $jobs = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $jobsUrl -Method Get
}
else {
    $jobs = Invoke-RestMethod -Uri $jobsUrl -UseDefaultCredentials -Method Post
}

if([string]::IsNullOrEmpty($result)) {
    $filteresJobs = $jobs.value | Where-Object { $_.PSobject.Properties.name -notcontains "result" }
}
else {
    $filteresJobs = $jobs.value.Where({ $_.result -eq $result })
}

return $filteresJobs

}