# . .\AzureDevOpsContext.ps1

Function Remove-ReleaseDef
{
    [CmdletBinding()]
param(
    [Parameter()][string]$releaseDefId,
    [Parameter()][string]$releaseDefName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

if([string]::IsNullOrEmpty($releaseDefId)) {
    $releaseDef = Get-ReleaseDefByName -releaseDefName $releaseDefName -context $context
    $releaseDefId = $releaseDef.id
}
$releaseDefUrl = $context.projectBaseUrl + '/release/definitions/' + $releaseDefId + '?api-version=' + $context.apiVersion
Write-Host $releaseDefUrl

if($context.isOnline) {
    $result = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $releaseDefUrl -Method Delete
}
else {
    $result = Invoke-RestMethod -Uri $releaseDefUrl -UseDefaultCredentials -Method Delete
}

return $result

}