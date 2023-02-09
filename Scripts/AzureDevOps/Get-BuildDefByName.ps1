# . .\AzureDevOpsContext.ps1

Function Get-BuildDefByName
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$buildDefName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$buildDefUrl = $context.projectBaseUrl + '/build/definitions?name=' + $buildDefName + '&api-version=' + $context.apiVersion
Write-Host $buildDefUrl

if($context.isOnline) {
    $buildDefs = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $buildDefUrl -Method Get
}
else {
    $buildDefs = Invoke-RestMethod -Uri $buildDefUrl -UseDefaultCredentials -Method Post
}

if($null -ne $buildDefs.value -and $buildDefs.value.length -gt 0) {
    return $buildDefs.value[0]
}
return $null

}