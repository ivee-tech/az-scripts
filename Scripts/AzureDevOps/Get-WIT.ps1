# . .\AzureDevOpsContext.ps1

Function Get-WIT
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$processId,
    [Parameter(Mandatory=$true)][string]$witRefName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)


$witUrl = $context.orgBaseUrl + '/work/processes/' + $processId + '/workitemtypes/' + $witRefName + '?api-version=' + $context.apiVersion
Write-Host $witUrl

if($context.isOnline) {
    $wit = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $witUrl -Method Get
}
else {
    $wit = Invoke-RestMethod -Uri $witUrl -UseDefaultCredentials -Method Get
}

return $wit

}