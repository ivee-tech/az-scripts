# . .\AzureDevOpsContext.ps1

Function Add-GitRepoBranchPolicy
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][PSCustomObject]$policy,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'
$data = ConvertTo-Json -InputObject $policy -Depth 10

$configUrl = $context.projectBaseUrl + '/policy/configurations?api-version=' + $context.apiVersion
Write-Host $configUrl
if($context.isOnline) {
    $response = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $configUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $response = Invoke-RestMethod -Uri $configUrl -Method Post -Body $data -ContentType $contentType -UseDefaultCredentials
}
return $response

}
