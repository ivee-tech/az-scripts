# . .\AzureDevOpsContext.ps1

Function Add-GitRepo
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$repoName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'

$projectApiUrl = $context.orgBaseUrl + '/projects/' + $context.project + '?api-version=' + $context.apiVersion
Write-Host $projectApiUrl
if($context.isOnline) {
    $projectResponse = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $projectApiUrl -Method Get
}
else {
    $projectResponse = Invoke-RestMethod -Uri $projectApiUrl -Method Get -UseDefaultCredentials
}

$projectId = $projectResponse.id
$data = '{
  "name": "' + $repoName + '",
  "project": {
    "name": "' + $context.project + '",
    "id": "' + $projectId + '"
  }
}
'
$repo = @{
    name = $repoName;
    project = @{
        name = $context.project;
        id = $projectId;
    }
}
$data = $repo | ConvertTo-Json

$gitRepoUrl = $context.projectBaseUrl + '/git/repositories?api-version=' + $context.apiVersion
Write-Host $gitRepoUrl
if($context.isOnline) {
    $repoResponse = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $gitRepoUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $repoResponse = Invoke-RestMethod -Uri $gitRepoUrl -Method Post -Body $data -ContentType $contentType -UseDefaultCredentials
}
$repoResponse

}
