# . .\AzureDevOpsContext.ps1

Function Get-GitRepo
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$repoName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$gitRepoUrl = $context.projectBaseUrl + '/git/repositories/' + $repoName + '?api-version=' + $context.apiVersion
Write-Host $gitRepoUrl
if($context.isOnline) {
    $repo = Invoke-WebRequest -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $gitRepoUrl -Method Get -UseBasicParsing
}
else {
    $repo = Invoke-WebRequest -Uri $gitRepoUrl -UseDefaultCredentials -Method Get -UseBasicParsing
}
return $repo.Content | ConvertFrom-Json

}