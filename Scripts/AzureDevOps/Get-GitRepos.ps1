# . .\AzureDevOpsContext.ps1

Function Get-GitRepos
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$gitReposUrl = $context.projectBaseUrl + '/git/repositories/?api-version=' + $context.apiVersion
Write-Host $gitReposUrl
if($context.isOnline) {
    $repo = Invoke-WebRequest -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $gitReposUrl -Method Get -UseBasicParsing
}
else {
    $repo = Invoke-WebRequest -Uri $gitReposUrl -UseDefaultCredentials -Method Get -UseBasicParsing
}
return $repo.Content | ConvertFrom-Json

}