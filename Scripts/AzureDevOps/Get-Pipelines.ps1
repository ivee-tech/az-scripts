# . .\AzureDevOpsContext.ps1

Function Get-Pipelines
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$ctHeader = 'X-MS-ContinuationToken'
$result = @{
    count = 0
    value = @()
}

$ct = $null
do {

$pipelinesUrl = $context.projectBaseUrl + '/pipelines?continuationToken=' + $ct + '&api-version=' + $context.apiVersion
Write-Host $pipelinesUrl

if($context.isOnline) {
    $r = Invoke-WebRequest -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $pipelinesUrl -Method Get
}
else {
    $r = Invoke-WebRequest -Uri $pipelinesUrl -UseDefaultCredentials -Method Get
}
$r
$obj = $r.Content | ConvertFrom-Json
$result.count += $obj.count
$result.value += $obj.value
$ct = $r.Headers[$ctHeader]

} while($null -ne $ct)

return $result

}