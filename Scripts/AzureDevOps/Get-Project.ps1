# . .\AzureDevOpsContext.ps1

Function Get-Project
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$projectName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$projectApiUrl = $context.orgBaseUrl + '/projects/' + $projectName + '?api-version=' + $context.apiVersion
Write-Host $projectApiUrl
if($context.isOnline) {
    $project = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $projectApiUrl -Method Get -UseBasicParsing
}
else {
    $project = Invoke-RestMethod -Uri $projectApiUrl -Method Get -UseDefaultCredentials -UseBasicParsing
}

return $project

}
