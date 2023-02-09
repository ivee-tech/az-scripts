# . .\AzureDevOpsContext.ps1

Function Get-Build
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][int]$buildId,
    [Parameter()][string]$propertyFilters, # <empty>, all, <specific property>
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$buildDefUrl = $context.projectBaseUrl + '/build/builds/' + $buildId + '?propertyFilters=' + $propertyFilters + '&api-version=' + $context.apiVersion
Write-Host $buildDefUrl

if($context.isOnline) {
    $buildDef = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $buildDefUrl -Method Get
}
else {
    $buildDef = Invoke-RestMethod -Uri $buildDefUrl -UseDefaultCredentials -Method Post
}

return $buildDef

}