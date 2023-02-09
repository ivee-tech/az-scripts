# . .\AzureDevOpsContext.ps1

Function Get-Processes
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$processesUrl = $context.orgBaseUrl + '/process/processes?api-version=' + $context.apiVersion

Write-Host $processesUrl
if($context.isOnline) {
    $processes = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $processesUrl -Method Get
}
else {
    $processes = Invoke-RestMethod -Uri $processesUrl -Method Get -UseDefaultCredentials
}

return $processes

}