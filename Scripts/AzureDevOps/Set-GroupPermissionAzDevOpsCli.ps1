# . .\AzureDevOpsContext.ps1

Function Set-GroupPermissionAzDevOpsCli
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$groupName,
    # for list of namespaces, use: az devops security permission namespace list --query "[].name"
    # for both ids and names, use: az devops security permission namespace list --query "[].{ namespaceId: namespaceId, name: name}"
    [Parameter()][string]$namespaceName,
    [Parameter()][string]$namespaceId,
    # for list of actions for a namespace, use: az devops security permission namespace list --query "[?@.name == '$namespaceName'].actions" 
    [Parameter(Mandatory=$true)][string]$actionName, 
    # Security token for the namespace, see this link for token guidance:
    # https://docs.microsoft.com/en-us/azure/devops/cli/security_tokens?view=azure-devops
    [Parameter(Mandatory=$true)][string]$securityToken, 
    [Parameter()][bool]$toggleAllow, #  $true for allow, $false for deny; use without $reset switch
    [Parameter()][switch]$reset, #  if used, reset the permission
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$currentLocation = Get-Location

$org = $context.org
$projName = $context.project

Set-Location $env:USERPROFILE

$subject = az devops security group list `
    --org "https://dev.azure.com/$org/" `
    --scope project `
    --project "$projName" `
    --subject-types vssgp `
    --query "graphGroups[?@.principalName == '[$projName]\$groupName'].descriptor | [0]"
Write-Host "subject: $subject"
 
if([String]::IsNullOrEmpty($namespaceId)) {
    $namespaceId = az devops security permission namespace list `
        --org "https://dev.azure.com/$org/" `
        --query "[?@.name == '$namespaceName'].namespaceId | [0]"
}
Write-Host "namespaceId: $namespaceId"

$bit = az devops security permission namespace show `
    --namespace-id $namespaceId `
    --org "https://dev.azure.com/$org/" `
    --query "[0].actions[?@.name == '$actionName'].bit | [0]"
Write-Host "bit: $bit"

if($reset) {
    az devops security permission reset `
    --id $namespaceId `
    --subject $subject `
    --token $securityToken `
    --permission-bit $bit `
    --org https://dev.azure.com/$org/ `
    --debug

}
else {
if($toggleAllow) {
        az devops security permission update `
            --id $namespaceId `
            --subject $subject `
            --token $securityToken `
            --allow-bit $bit `
            --merge true `
            --org https://dev.azure.com/$org/ `
            --debug
    }
    else {
        az devops security permission update `
            --id $namespaceId `
            --subject $subject `
            --token $securityToken `
            --deny-bit $bit `
            --merge true `
            --org https://dev.azure.com/$org/ `
            --debug
    }
}
Set-Location $currentLocation

}


