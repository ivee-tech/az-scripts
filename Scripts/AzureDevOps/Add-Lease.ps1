# . .\AzureDevOpsContext.ps1

Function Add-Lease
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][int]$definitionId,
    [Parameter(Mandatory=$true)][int]$runId,
    [Parameter(Mandatory=$true)][int]$daysValid,
    # $ownerId = [Branch:<repoId:branch>, Pipeline:<pipelineId>, User:<userId>]
    [Parameter(Mandatory=$true)][string]$ownerId, 
    [Parameter()][switch]$protectPipeline,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'

# POST https://dev.azure.com/{organization}/{project}/_apis/build/retention/leases?api-version=7.0
$leaseUrl = $context.projectBaseUrl + '/build/retention/leases?api-version=' + $context.apiVersion
Write-Host $leaseUrl

$lease = @(@{
    definitionId = $definitionId
    runId = $runId
    daysValid = $daysValid
    ownerId = $ownerId
    protectPipeline = if($protectPipeline){$true}else{$false}
})
$data = ConvertTo-Json -InputObject $lease
Write-Host $data

if($context.isOnline) {
    $leases = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $leaseUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $leases = Invoke-RestMethod -Uri $leaseUrl -UseDefaultCredentials -Method Post -Body $data -ContentType $contentType
}

return $leases

}
