# . .\AzureDevOpsContext.ps1

Function Set-Lease
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][int]$leaseId,
    [Parameter(Mandatory=$true)][int]$daysValid,
    [Parameter()][switch]$protectPipeline,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'

# PATCH https://dev.azure.com/{organization}/{project}/_apis/build/retention/leases/{leaseId}?api-version=7.0
$leaseUrl = $context.projectBaseUrl + '/build/retention/leases/' + $leaseId + '?api-version=' + $context.apiVersion
Write-Host $leaseUrl

$lease = @{
    daysValid = $daysValid
    protectPipeline = if($protectPipeline){$true}else{$false}
}
$data = ConvertTo-Json -InputObject $lease
Write-Host $data

if($context.isOnline) {
    $lease = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $leaseUrl -Method Patch -Body $data -ContentType $contentType
}
else {
    $lease = Invoke-RestMethod -Uri $leaseUrl -UseDefaultCredentials -Method Patch -Body $data -ContentType $contentType
}

return $lease

}
