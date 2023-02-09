# . .\AzureDevOpsContext.ps1

Function Import-BuildDef
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$jsonDefFilePath,
    [Parameter(Mandatory=$true)][string]$buildDefName,
    [Parameter(Mandatory=$true)][string]$projectId,
    [Parameter(Mandatory=$true)][string]$projectName,
    [Parameter(Mandatory=$true)][string]$repoId,
    [Parameter(Mandatory=$true)][string]$repoName,
    [Parameter()][string]$taskGroupId,
    [ValidateSet("", "project", "projectCollection")]
    [Parameter()][string]$jobAuthorizationScope,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$json = Get-Content -Path $jsonDefFilePath -Raw
$buildDef = ConvertFrom-Json -InputObject $json
$buildDef.name = $buildDefName
$buildDef.project.id = $projectId
$buildDef.project.name = $projectName
$buildDef.repository.id = $repoId
$buildDef.repository.name = $repoName
$buildDef.queue.id = $null
if(![string]::IsNullOrEmpty($taskGroupId)) {
    $buildDef.process.phases[0].steps[0].task.id = $taskGroupId
}
if(![string]::IsNullOrEmpty($jobAuthorizationScope)) {
    $buildDef.jobAuthorizationScope = $jobAuthorizationScope
}

$contentType = 'application/json'

$buildDefUrl = $context.projectBaseUrl + '/build/definitions?api-version=' + $context.apiVersion
Write-Host $buildDefUrl

$data = ConvertTo-Json -InputObject $buildDef -Depth 100

if($context.isOnline) {
    $newBuildDef = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $buildDefUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $newBuildDef = Invoke-RestMethod -Uri $buildDefUrl -UseDefaultCredentials -Method Post -Body $data -ContentType $contentType
}

return $newBuildDef

}