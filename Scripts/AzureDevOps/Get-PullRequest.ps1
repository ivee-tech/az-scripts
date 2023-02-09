# . .\AzureDevOpsContext.ps1
# . .\Get-GitRepo.ps1

Function Get-PullRequest
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$repoName,
    [Parameter(Mandatory=$true)][int]$pullRequestId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$repo = Get-GitRepo -repoName $repoName -context $context

$pullRequestUrl = $context.projectBaseUrl + '/git/repositories/' + $repo.id +'/pullrequests/' + $pullRequestId + '?api-version=' + $context.apiVersion
$pullRequestUrl

if($context.isOnline) {
    $pullRequest = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $pullRequestUrl -Method Get
}
else {
    $pullRequest = Invoke-RestMethod -Uri $pullRequestUrl -UseDefaultCredentials -Method Get
}

return $pullRequest

}