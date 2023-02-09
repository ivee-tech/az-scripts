# . .\AzureDevOpsContext.ps1

Function Get-VarGroupVars
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter()][string]$varGroupId,
    [Parameter()][string]$varGroupName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

if([string]::IsNullOrEmpty($varGroupId)) {
    $varGroup = Get-VarGroupByName -varGroupName $varGroupName -context $context
    $varGroupId = $varGroup.id
} 
else {
    $varGroup = Get-VarGroup -groupId $varGroupId -context $context
}

$vars = @{}
$varGroup.variables.PSObject.Properties | ForEach-Object { 
    $key = $_.Name
    $value = $_.Value.value
    $vars[$key] = $value;
 }
 
 return $vars

}