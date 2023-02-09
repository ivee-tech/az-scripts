# . .\AzureDevOpsContext.ps1

Function Remove-BuildDef
{
    [CmdletBinding()]
param(
    [Parameter()][string]$buildDefId,
    [Parameter()][string]$buildDefName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

if([string]::IsNullOrEmpty($buildDefId)) {
    $buildDef = Get-BuildDefByName -releaseDefName $buildDefName -context $context
    $buildDefId = $buildDef.id
}
$buildDefUrl = $context.projectBaseUrl + '/build/definitions/' + $buildDefId + '?api-version=' + $context.apiVersion
Write-Host $buildDefUrl

if($context.isOnline) {
    $result = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $buildDefUrl -Method Delete
}
else {
    $result = Invoke-RestMethod -Uri $buildDefUrl -UseDefaultCredentials -Method Delete
}

return $result

}