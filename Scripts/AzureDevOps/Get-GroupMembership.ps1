# . .\AzureDevOpsContext.ps1
# . .\Get-Group.ps1

Function Get-GroupMembership
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$projectName,
    [Parameter(Mandatory=$true)][string]$groupName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$group = Get-Group -projectName $projectName -groupName $groupName -context $context
if($null -eq $group) {
    Write-Host "Group $groupName cannot be found in project $projectName."
    return $null
}

$members = az devops security group membership list `
    --organization "$($context.orgUrl)" `
    --id $group.descriptor

return $members # | ConvertFrom-Json

}
