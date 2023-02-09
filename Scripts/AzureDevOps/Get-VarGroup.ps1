# . .\AzureDevOpsContext.ps1

Function Get-VarGroup
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][int]$groupId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$varGroupUrl = $context.projectBaseUrl + '/distributedtask/variablegroups/' + $groupId + '?api-version=' + $context.apiVersion
$varGroupUrl


if($context.isOnline) {
    $varGroup = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $varGroupUrl -Method Get
}
else {
    $varGroup = Invoke-RestMethod -Uri $varGroupsUrl -UseDefaultCredentials -Method Get
}

return $varGroup
<#
# $varGroup.variables | Get-Member -MemberType 'NoteProperty' | Select-Object -ExpandProperty $_.Name # | ConvertTo-Json
$props = Get-Member -InputObject $varGroup.variables -MemberType NoteProperty

foreach($prop in $props) {
    $propValue = $varGroup.variables | Select-Object -ExpandProperty $prop.Name
    "$($prop.Name),""$($propValue.value)"""
}
#>

}