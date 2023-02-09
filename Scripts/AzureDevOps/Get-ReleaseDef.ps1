# . .\AzureDevOpsContext.ps1

Function Get-ReleaseDef
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$releaseDefId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$releaseDefUrl = $context.projectBaseUrl + '/release/definitions/' + $releaseDefId + '?api-version=' + $context.apiVersion
Write-Host $releaseDefUrl

if($context.isOnline) {
    $releaseDef = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $releaseDefUrl -Method Get
}
else {
    $releaseDef = Invoke-RestMethod -Uri $releaseDefUrl -UseDefaultCredentials -Method Get
}

return $releaseDef

}