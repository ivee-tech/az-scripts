# . .\AzureDevOpsContext.ps1

Function Copy-BuildDefinition
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$buildPath,
    [Parameter(Mandatory=$true)][int]$buildDefId,
    [Parameter(Mandatory=$true)][string]$buildDefName,
    [Parameter(Mandatory=$true)][string]$repoName,
    [Parameter(Mandatory=$true)][string]$varGroupName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$srcCtx,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$destCtx
)


$srcVersion = $srcCtx.apiVersion
$destVersion = $destCtx.apiVersion + '-preview.1'

$destProjListUrl = $destCtx.orgBaseUrl + '/projects?api-version=' + $destVersion
if($destCtx.isOnline) {
    $destProjList = Invoke-RestMethod -Headers @{Authorization="Basic $($destCtx.base64AuthInfo)"} -Uri $destProjListUrl
}
else {
    $destProjList = Invoke-RestMethod -Uri $destProjListUrl -UseDefaultCredentials
}
$destProjObj = $destProjList.value | Where-Object{$_.name -eq $destCtx.project } # | ConvertTo-Json

$varGroupsUrl = $destCtx.projBaseUrl + '/distributedtask/variablegroups/?groupName=' + $varGroupName + '&api-version=' + $destVersion
if($destCtx.isOnline) {
    $varGroups = Invoke-RestMethod -Headers @{Authorization="Basic $($destCtx.base64AuthInfo)"} -Uri $varGroupsUrl -Method Get
}
else {
    $varGroups = Invoke-RestMethod -Uri $varGroupsUrl -UseDefaultCredentials -Method Get
}
$varGroups
$varGroup = $varGroups.value # | Where-Object { $_ -eq $varGroupName }
$varGroup

$buildGetUrl = $srcCtx.projBaseUrl + '/build/definitions/' + $buildDefId + '?api-version=' + $srcVersion
$buildGetUrl
if($srcCtx.isOnline) {
    $buildDef = Invoke-RestMethod -Headers @{Authorization="Basic $($srcCtx.base64AuthInfo)"} -Uri $buildGetUrl
}
else {
    $buildDef = Invoke-RestMethod -Uri $buildGetUrl -UseDefaultCredentials
}

$gitRepoUrl = $destCtx.projBaseUrl + '/git/repositories/' + $repoName + '?api-version=' + $destVersion
$gitRepoUrl
if($destCtx.isOnline) {
    $repo = Invoke-RestMethod -Headers @{Authorization="Basic $($destCtx.base64AuthInfo)"} -Uri $gitRepoUrl
}
else {
    $repo = Invoke-RestMethod -Uri $gitRepoUrl -UseDefaultCredentials
}

$buildCreateUrl = $destCtx.projBaseUrl + '/build/definitions?&api-version=' + $destCtx.apiVersion
$newBuildDefName = $buildDefName # + '-' + $area

$buildDef.path = $buildPath
$buildDef.project.id = $destProjObj.id
$buildDef.project.name = $destProjObj.name
$buildDef.name = $newBuildDefName
$buildDef.repository.name = $repo.name
$buildDef.repository.id = $repo.id
$buildDef.repository.url = $repo.url
$buildDef.queue.id = 104 # TODO: use parameter
$buildDef.queue.name = 'ubuntu-18.04' # TODO: use parameter
$buildDef.queue.pool.id = 104
$buildDef.queue.pool.name = 'ubuntu-18.04'
$buildDef.variableGroups.Clear()
$buildDef.variableGroups += $varGroup



$data = $buildDef | ConvertTo-Json -Depth 100

if($destCtx.isOnline) {
    $response = Invoke-RestMethod -Headers @{Authorization="Basic $($destCtx.base64AuthInfo)"} -Uri $buildCreateUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $response = Invoke-RestMethod -Uri $buildCreateUrl -Method Post -Body $data -ContentType $contentType -UseDefaultCredentials
}

return $response

}