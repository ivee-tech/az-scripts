# . .\AzureDevOpsContext.ps1
# . .\Get-AzureDevOpsContext.ps1
# . .\Get-Groups.ps1

Function Get-Group
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$projectName,
    [Parameter(Mandatory=$true)][string]$groupName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$groups = Get-Groups -projectName $projectName -context $context

$group = $groups.value | Where-Object { $_.principalName -eq "[$projectName]\$groupName" }
return $group

}
