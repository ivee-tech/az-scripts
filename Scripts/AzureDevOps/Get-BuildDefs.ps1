# . .\AzureDevOpsContext.ps1

Function Get-BuildDefs
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

$buildDefUrl = $context.projectBaseUrl + '/build/definitions?queryOrder=definitionNameAscending&continuationToken=' + $ct + '&api-version=' + $context.apiVersion
Write-Host $buildDefUrl

if($context.isOnline) {
    $r = Invoke-WebRequest -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $buildDefUrl -Method Get
}
else {
    $r = Invoke-WebRequest -Uri $buildDefUrl -UseDefaultCredentials -Method Get
}
$r
$obj = $r.Content | ConvertFrom-Json
$result.count += $obj.count
$result.value += $obj.value
$ct = $r.Headers[$ctHeader]

} while($null -ne $ct)

return $result

}