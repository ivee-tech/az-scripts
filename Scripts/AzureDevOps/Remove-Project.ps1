# . .\AzureDevOpsContext.ps1
# . .\Get-Project.ps1

Function Remove-Project
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$name,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$project = Get-Project -projectName $name -context $context
$projectUrl = $context.orgBaseUrl + '/projects/' + $project.id + '?api-version=' + $context.apiVersion
Write-Host $projectUrl

if($context.isOnline) {
    $response = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $projectUrl -Method Delete
}
else {
    $response = Invoke-RestMethod -Uri $projectUrl -UseDefaultCredentials -Method Delete
}

return $response

}