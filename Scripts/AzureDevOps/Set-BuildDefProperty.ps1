# . .\AzureDevOpsContext.ps1

Function Set-BuildDefProperty
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][int]$buildDefId,
    [ValidateSet("add", "remove", "replace")]
    [Parameter(Mandatory=$true)][string]$op,
    [Parameter(Mandatory=$true)][string]$propertyPath,
    [Parameter(Mandatory=$true)][string]$propertyValue,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json-patch+json'
$v = $context.apiVersion + '-preview.1'

$buildDefUrl = $context.projectBaseUrl + '/build/definitions/' + $buildDefId + '/properties?api-version=' + $v
Write-Host $buildDefUrl

$props = @(
    @{
        op = $op;
        path = $propertyPath;
        value = $propertyValue
    }
)
$data = ConvertTo-Json -InputObject $props -Depth 10

if($context.isOnline) {
    $result = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $buildDefUrl -Method Patch -Body $data -ContentType $contentType
}
else {
    $result = Invoke-RestMethod -Uri $buildDefUrl -UseDefaultCredentials -Method Patch -Body $data -ContentType $contentType
}

return $result

}