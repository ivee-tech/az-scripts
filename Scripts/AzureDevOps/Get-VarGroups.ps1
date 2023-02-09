# . .\AzureDevOpsContext.ps1

Function Get-VarGroups
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.2'
$varGroupsUrl = $context.projectBaseUrl + '/distributedtask/variablegroups?api-version=' + $v
$varGroupsUrl


if($context.isOnline) {
    $varGroups = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $varGroupsUrl -Method Get
}
else {
    $varGroups = Invoke-RestMethod -Uri $varGroupsUrl -UseDefaultCredentials -Method Get
}

return $varGroups

}