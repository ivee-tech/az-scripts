# . .\AzureDevOpsContext.ps1

Function Get-VarGroupByName
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$varGroupName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$varGroups = Get-VarGroups -context $context
if($null -ne $varGroups.value -and $varGroups.value.length -gt 0) {
    $varGroup = $varGroups.value | Where-Object { $_.name -eq $varGroupName }
    return $varGroup
}
return $null

}