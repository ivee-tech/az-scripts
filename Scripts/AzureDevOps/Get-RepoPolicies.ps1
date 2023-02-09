# . .\AzureDevOpsContext.ps1

Function Get-RepoPolicies
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$policiesUrl = $context.projectBaseUrl + '/policy/configurations?api-version=' + $context.apiVersion
Write-Host $policiesUrl
if($context.isOnline) {
    $policies = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $policiesUrl -Method Get
}
else {
    $policies = Invoke-RestMethod -Uri $policiesUrl -Method Get -UseDefaultCredentials
}

return $policies

}
