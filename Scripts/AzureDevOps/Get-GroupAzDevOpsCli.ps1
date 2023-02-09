# . .\AzureDevOpsContext.ps1

Function Get-GroupAzDevOpsCli
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$projectName,
    [Parameter(Mandatory=$true)][string]$groupName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$group = az devops security group list `
    --organization "$($context.orgUrl)" `
    --project "$projectName" `
    --query "@.graphGroups[?@.principalName == '[$projectName]\$groupName'] | [0]"

return $group | ConvertFrom-Json

}
