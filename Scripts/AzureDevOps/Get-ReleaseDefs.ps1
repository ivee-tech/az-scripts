# . .\AzureDevOpsContext.ps1

Function Get-ReleaseDefs
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

$releaseDefsUrl = $context.projectBaseUrl + '/release/definitions?queryOrder=nameAscending&continuationToken=' + $ct + '&api-version=' + $context.apiVersion
Write-Host $releaseDefsUrl

if($context.isOnline) {
    $r = Invoke-WebRequest -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $releaseDefsUrl -Method Get
}
else {
    $r = Invoke-WebRequest -Uri $releaseDefsUrl -UseDefaultCredentials -Method Get
}

$obj = $r.Content | ConvertFrom-Json 
$result.count += $obj.count
$result.value += $obj.value
$ct = $r.Headers[$ctHeader]

} while($null -ne $ct)

return $result

}