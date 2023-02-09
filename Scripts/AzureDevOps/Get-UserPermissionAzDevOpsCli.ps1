
Function Get-UserPermissionAzDevOpsCli
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$userName, # Email or ID
    # for list of namespaces, use: az devops security permission namespace list --query "[].name"
    # for both ids and names, use: az devops security permission namespace list --query "[].{ namespaceId: namespaceId, name: name}"
    [Parameter()][string]$namespaceName,
    [Parameter()][string]$namespaceId,
    # Security token for the namespace, see this link for token guidance:
    # https://docs.microsoft.com/en-us/azure/devops/cli/security_tokens?view=azure-devops
    [Parameter(Mandatory=$true)][string]$securityToken, 
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$currentLocation = Get-Location

$org = $context.org

Set-Location $env:USERPROFILE

$subject = az devops user show `
    --org "https://dev.azure.com/$org/" `
    --user $userName `
    --query "user.descriptor"
Write-Host "subject: $subject"
 
if([String]::IsNullOrEmpty($namespaceId)) {
    $namespaceId = az devops security permission namespace list `
        --org "https://dev.azure.com/$org/" `
        --query "[?@.name == '$namespaceName'].namespaceId | [0]"
}
Write-Host "namespaceId: $namespaceId"

az devops security permission show `
    --id $namespaceId `
    --subject $subject `
    --token $securityToken `
    --org https://dev.azure.com/$org/

Set-Location $currentLocation

}


