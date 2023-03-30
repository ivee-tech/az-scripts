# . .\AzureDevOpsContext.ps1

Function Get-TeamIterations
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$teamName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

# GET https://dev.azure.com/{organization}/{project}/{team}/_apis/work/teamsettings/iterations?api-version=7.1-preview.1
$v = $context.apiVersion + '-preview.1'
$iterationsUrl = $context.orgUrl + '/' + $context.$project + '/' + $teamName + '/_apis/work/teamsettings/iterations?api-version=' + $v
Write-Host $iterationsUrl
if($context.isOnline) {
    $project = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $iterationsUrl -Method Get -UseBasicParsing
}
else {
    $project = Invoke-RestMethod -Uri $iterationsUrl -Method Get -UseDefaultCredentials -UseBasicParsing
}

return $project

}
