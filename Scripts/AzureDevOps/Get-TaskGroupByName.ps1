# . .\AzureDevOpsContext.ps1
# . .\Get-TaskGroups.ps1

Function Get-TaskGroupByName
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$taskGroupName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$taskGroups = Get-TaskGroups -context $context 
$taskGroup = $taskGroups.value | Where-Object { $_.name -eq $taskGroupName }
return $taskGroup

}