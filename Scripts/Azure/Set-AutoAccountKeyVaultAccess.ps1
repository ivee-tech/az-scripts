Function Set-AutoAccountKeyVaultAccess {
    [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$rgName,
    [Parameter(Mandatory=$true)][string]$autoAccountName,
    [Parameter(Mandatory=$true)][string]$kvName
)

# Grant access to the Key Vault to the Automation Run As account.
$connection = Get-AzAutomationConnection -ResourceGroupName $rgName -AutomationAccountName $autoAccountName -Name AzureRunAsConnection
$appID = $connection.FieldDefinitionValues.ApplicationId
Set-AzKeyVaultAccessPolicy -VaultName $kvName -ServicePrincipalName $appID -PermissionsToSecrets Set, Get

}
