# . .\AzureDevOpsContext.ps1

Function Add-Team
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$name,
    [Parameter(Mandatory=$true)][string]$description,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'

$teamsUrl = $context.orgBaseUrl + '/projects/' + $context.project + '/teams?api-version=' + $context.apiVersion
Write-Host $projectsUrl

$data = @{
    name = $name;
    description = $description;
} | ConvertTo-Json -Depth 10

if($context.isOnline) {
    $team = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $teamsUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $team = Invoke-RestMethod -Uri $teamsUrl -UseDefaultCredentials -Method Post -Body $data -ContentType $contentType
}

return $team

}