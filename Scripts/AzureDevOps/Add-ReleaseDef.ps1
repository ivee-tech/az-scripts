# . .\AzureDevOpsContext.ps1

Function Add-ReleaseDef
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][PSCustomObject]$def,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'

$releasesDefUrl = $context.projectBaseUrl + '/release/definitions?api-version=' + $context.apiVersion
Write-Host $releasesDefUrl

$data = $def | ConvertTo-Json -Depth 10

if($context.isOnline) {
    $releaseDef = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $releasesDefUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $releaseDef = Invoke-RestMethod -Uri $releasesDefUrl -UseDefaultCredentials -Method Post -Body $data -ContentType $contentType
}

return $releaseDef

}