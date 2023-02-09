# . .\AzureDevOpsContext.ps1

Function Remove-GitRepoBranchPolicy
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$policyId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)


$configUrl = $context.projectBaseUrl + '/policy/configurations/' + $policyId + '?api-version=' + $context.apiVersion
Write-Host $configUrl
if($context.isOnline) {
    $response = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $configUrl -Method Delete
}
else {
    $response = Invoke-RestMethod -Uri $configUrl -Method Delete -UseDefaultCredentials
}
return $response

}
