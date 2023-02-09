# . .\AzureDevOpsContext.ps1

Function Get-ReleaseDefByName
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$releaseDefName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$releaseDefUrl = $context.projectBaseUrl + '/release/definitions?searchText=' + $releaseDefName + '&api-version=' + $context.apiVersion
Write-Host $releaseDefUrl

if($context.isOnline) {
    $releaseDefs = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $releaseDefUrl -Method Get
}
else {
    $releaseDefs = Invoke-RestMethod -Uri $releaseDefUrl -UseDefaultCredentials -Method Get
}

if($null -ne $releaseDefs.value -and $releaseDefs.value.length -gt 0) {
    return $releaseDefs.value[0]
}

return $null

}