# . .\AzureDevOpsContext.ps1

Function Remove-GitRepo
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$repoId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$gitRepoUrl = $context.projectBaseUrl + '/git/repositories/' + $repoId + '?api-version=' + $context.apiVersion
Write-Host $gitRepoUrl
if($context.isOnline) {
    $repoResponse = Invoke-WebRequest -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $gitRepoUrl -Method Delete
}
else {
    $repoResponse = Invoke-WebRequest -Uri $gitRepoUrl -UseDefaultCredentials -Method Delete
}
$repoResponse

}