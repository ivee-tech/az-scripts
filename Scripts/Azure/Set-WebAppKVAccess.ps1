Function Set-WebAppKVAccess
{
param(
    [Parameter(Mandatory=$true)]$rgName,
    [Parameter(Mandatory=$true)]$webAppName,
    [Parameter(Mandatory=$true)]$rgNameKeyVault,
    [Parameter(Mandatory=$true)]$keyVaultName
)

$site = Set-AzWebApp -AssignIdentity $true -Name $webAppName -ResourceGroupName $rgName
$site.Identity

<#
$context = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext
$graphToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, 
    $context.Environment, $context.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, 
    "https://graph.microsoft.com").AccessToken
$aadToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, 
    $context.Environment, $context.Tenant.Id.ToString(), $null, 
    [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, "https://graph.windows.net").AccessToken
 
Write-Output "$($context.Account.Id)"

Connect-AzureAD -AadAccessToken $aadToken -AccountId $context.Account.Id -TenantId $context.tenant.id

$principal = Get-AzADServicePrincipal -DisplayName $webAppName
#>
Set-AzKeyVaultAccessPolicy -VaultName $keyVaultName -ResourceGroupName $rgNameKeyVault -ObjectId $site.Identity.PrincipalId -PermissionsToSecrets get,list
}