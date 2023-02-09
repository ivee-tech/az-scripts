# . .\AzureDevOpsContext.ps1
# . .\Get-Project.ps1
# . .\Get-GitRepo.ps1
# . .\Get-User.ps1
# . .\Get-Group.ps1

Function Import-PullRequest
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$jsonDefFilePath,
    [Parameter(Mandatory=$true)][string]$repoName,
    [Parameter(Mandatory=$true)][string]$title,
    [Parameter(Mandatory=$true)][string]$description,
    [Parameter(Mandatory=$true)][string]$sourceBranchName,
    [Parameter(Mandatory=$true)][string]$targetBranchName,
    [Parameter(Mandatory=$true)][string]$reviewerId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'

$json = Get-Content -Path $jsonDefFilePath -Raw
$pullRequest = ConvertFrom-Json -InputObject $json

$project = Get-Project -projectName $context.project -context $context
$repo = Get-GitRepo -repoName $repoName -context $context
$pullRequest.repository.id = $repo.id
$pullRequest.repository.name = $repoName
$pullRequest.repository.project.id = $project.id
$pullRequest.repository.project.name = $project.name
$pullRequest.title = $title
$pullRequest.description = $description
$pullRequest.sourceRefName = "refs/heads/$sourceBranchName"
$pullRequest.targetRefName = "refs/heads/$targetBranchName"

$pullRequest.reviewers += @{ id = $reviewerId }

$pullRequestUrl = $context.orgBaseUrl + '/git/repositories/' + $repo.id + '/pullrequests?api-version=' + $context.apiVersion
Write-Host $projectsUrl

$data = $pullRequest | ConvertTo-Json -Depth 10

if($context.isOnline) {
    $newPullRequest = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $pullRequestUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $newPullRequest = Invoke-RestMethod -Uri $pullRequestUrl -UseDefaultCredentials -Method Post -Body $data -ContentType $contentType
}

return $newPullRequest

}