# . .\AzureDevOpsContext.ps1

Function Get-ServiceEndpointByName
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$endpointName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.4'
$endpointUrl = $context.projectBaseUrl + '/serviceendpoint/endpoints?endpointNames=' + $endpointName + '&api-version=' + $v
Write-Host $endpointUrl

if($context.isOnline) {
    $endpoints = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $endpointUrl -Method Get
}
else {
    $endpoints = Invoke-RestMethod -Uri $endpointUrl -UseDefaultCredentials -Method Get
}

if($null -ne $endpoints.value -and $endpoints.value.length -gt 0) {
    return $endpoints.value[0]
}

return $null

}