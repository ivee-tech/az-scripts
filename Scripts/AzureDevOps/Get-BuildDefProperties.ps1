# . .\AzureDevOpsContext.ps1

Function Get-BuildDefProperties
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][int]$buildDefId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'
$buildDefPropsUrl = $context.projectBaseUrl + '/build/definitions/' + $buildDefId + '/properties?api-version=' + $v
Write-Host $buildDefUrl

if($context.isOnline) {
    $buildDefProps = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $buildDefPropsUrl -Method Get
}
else {
    $buildDefProps = Invoke-RestMethod -Uri $buildDefPropsUrl -UseDefaultCredentials -Method Post
}

return $buildDefProps

}