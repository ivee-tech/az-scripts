# . .\AzureDevOpsContext.ps1

Function Import-ReleaseDef
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$jsonDefFilePath,
    [Parameter(Mandatory=$true)][string]$releaseDefName,
    [Parameter(Mandatory=$true)][string]$projectId,
    [Parameter(Mandatory=$true)][string]$buildDefId,
    [Parameter(Mandatory=$true)][string]$buildDefName,
    [Parameter(Mandatory=$true)][string]$ownerId,
    [Parameter(Mandatory=$true)][string]$approverId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$json = Get-Content -Path $jsonDefFilePath -Raw
$releaseDef = ConvertFrom-Json -InputObject $json
$releaseDef.name = $releaseDefName
$releaseDef.artifacts[0].sourceId = "$($projectId):$($buildDefId)"
$releaseDef.artifacts[0].alias = "_$($buildDefName)"
$releaseDef.artifacts[0].definitionReference.definition.id = $buildDefId
$releaseDef.artifacts[0].definitionReference.definition.name = $buildDefName
$releaseDef.artifacts[0].definitionReference.project.id = $projectId
$releaseDef.environments | ForEach-Object { 
    $_.deployPhases[0].deploymentInput.queueId = $null
    $_.owner.id = $ownerId
}
if($releaseDef.environments.length -gt 0) {
    $releaseDef.environments[1].preDeployApprovals.approvals[0].approver.id = $approverId
}
$releaseDef.triggers[0].artifactAlias = "_$($buildDefName)"
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