# . .\AzureDevOpsContext.ps1

Function Add-BuildDef
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][PSCustomObject]$def,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'

$buildDefsUrl = $context.projectBaseUrl + '/build/definitions?api-version=' + $context.apiVersion
Write-Host $projectsUrl

$data = $def | ConvertTo-Json -Depth 10

if($context.isOnline) {
    $buildDef = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $buildDefsUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $buildDef = Invoke-RestMethod -Uri $buildDefsUrl -UseDefaultCredentials -Method Post -Body $data -ContentType $contentType
}

return $buildDef

}