# . .\AzureDevOpsContext.ps1
# . .\Get-Project.ps1
Function Remove-ServiceEndpoint
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter()][string]$endpointId,
    [Parameter()][string]$endpointName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

if([string]::IsNullOrEmpty($endpointId)) {
  $endpoint = Get-ServiceEndpointByName -endpointName $endpointName -context $context
  $endpointId = $endpoint.id
}
$project = Get-Project -projectName $context.project -context $context

$v = $context.apiVersion + '-preview.4'
$endpointUrl = $context.orgBaseUrl + '/serviceendpoint/endpoints/' + $endpointId + '?projectIds=' + $project.id + '&api-version=' + $v

if($context.isOnline) {
    $result = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $endpointUrl -Method Delete
}
else {
    $result = Invoke-RestMethod -Uri $endpointUrl -UseDefaultCredentials -Method Delete
}

return $result

}