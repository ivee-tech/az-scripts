# . .\AzureDevOpsContext.ps1

Function Get-RepoPolicyTypes
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$policyTypesUrl = $context.projectBaseUrl + '/policy/types?api-version=' + $context.apiVersion
Write-Host $policyTypesUrl
if($context.isOnline) {
    $policyTypes = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $policyTypesUrl -Method Get
}
else {
    $policyTypes = Invoke-RestMethod -Uri $policyTypesUrl -Method Get -UseDefaultCredentials
}

return $policyTypes

}
