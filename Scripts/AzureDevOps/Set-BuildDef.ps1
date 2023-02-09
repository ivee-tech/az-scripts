# . .\AzureDevOpsContext.ps1

Function Set-BuildDef
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][int]$buildDefId,
    [Parameter(Mandatory=$true)][hashtable]$buildDef,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)


$contentType = 'application/json'

$buildDefUrl = $context.projectBaseUrl + '/build/definitions/' + $buildDefId + '?api-version=' + $context.apiVersion
Write-Host $buildDefUrl

$data = ConvertTo-Json -InputObject $buildDef -Depth 100

if($context.isOnline) {
    $newBuildDef = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $buildDefUrl -Method Put -Body $data -ContentType $contentType
}
else {
    $newBuildDef = Invoke-RestMethod -Uri $buildDefUrl -UseDefaultCredentials -Method Put -Body $data -ContentType $contentType
}

return $newBuildDef

}