# . .\AzureDevOpsContext.ps1
# . .\Get-Projects.ps1
# . .\Get-GroupAzDevOpsCli.ps1
# . .\Get-GroupMembership.ps1

Function Get-OrgGroupMembership
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$groupName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$projects = Get-Projects -context $context
$groupsMembers = @()
$projects | ForEach-Object {
    $groupMembers = @{}
    $groupMembers.groupName = "[$($_.name)]\$groupName"
    $members = (Get-GroupMembership -projectName $_.name -groupName $groupName -context $context) | ConvertFrom-Json
    $mbs = @()
    $members.PSObject.Properties | ForEach-Object { $mbs += $_.Value }
    $groupMembers.members = $mbs

    $groupsMembers += $groupMembers
}

return $groupsMembers

}
