# . .\AzureDevOpsContext.ps1

Function Import-SimpleReleaseDef
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$jsonDefFilePath,
    [Parameter(Mandatory=$true)][string]$releaseDefName,
    [Parameter(Mandatory=$true)][string]$ownerId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$json = Get-Content -Path $jsonDefFilePath -Raw
$releaseDef = ConvertFrom-Json -InputObject $json
$releaseDef.name = $releaseDefName
$releaseDef.environments | ForEach-Object { 
    $_.deployPhases[0].deploymentInput.queueId = $null
    $_.owner.id = $ownerId
}
$releaseDef.id = $null

$contentType = 'application/json'

$releaseDefUrl = $context.projectBaseUrl + '/release/definitions?api-version=' + $context.apiVersion
Write-Host $releaseDefUrl

$data = ConvertTo-Json -InputObject $releaseDef -Depth 100

if($context.isOnline) {
    $newReleaseDef = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $releaseDefUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $newReleaseDef = Invoke-RestMethod -Uri $releaseDefUrl -UseDefaultCredentials -Method Post -Body $data -ContentType $contentType
}

return $newReleaseDef

}