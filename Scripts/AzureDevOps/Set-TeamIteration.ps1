# . .\AzureDevOpsContext.ps1

Function Set-TeamIteration
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$teamName,
    [Parameter(Mandatory=$true)][string]$iterationIdentitifer,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'

# POST https://dev.azure.com/{organization}/{project}/{team}/_apis/work/teamsettings/iterations?api-version=7.0
$v = $context.apiVersion
$teamsUrl = $context.orgUrl + '/' + $context.project + '/' + $teamName + '/_apis/work/teamsettings/iterations?api-version=' + $v
Write-Host $teamsUrl

$data = @{
    id = $iterationIdentitifer;
} | ConvertTo-Json

if($context.isOnline) {
    $team = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $teamsUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $team = Invoke-RestMethod -Uri $teamsUrl -UseDefaultCredentials -Method Post -Body $data -ContentType $contentType
}

return $team

}