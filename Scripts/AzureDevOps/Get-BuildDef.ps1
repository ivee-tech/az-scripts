# . .\AzureDevOpsContext.ps1

Function Get-BuildDef
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][int]$buildDefId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$buildDefUrl = $context.projectBaseUrl + '/build/definitions/' + $buildDefId + '?api-version=' + $context.apiVersion
Write-Host $buildDefUrl

if($context.isOnline) {
    $buildDef = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $buildDefUrl -Method Get
}
else {
    $buildDef = Invoke-RestMethod -Uri $buildDefUrl -UseDefaultCredentials -Method Get
}

return $buildDef

}