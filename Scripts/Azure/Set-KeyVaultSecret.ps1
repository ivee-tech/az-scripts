Function Set-KeyVaultSecret
{
param(
	[Parameter(Mandatory=$true)][string]$rgName,
	[Parameter(Mandatory=$true)][string]$keyVaultName,
	[Parameter(Mandatory=$true)][string]$secretName,
	[Parameter(Mandatory=$true)][string]$secretValue
)

$secureValue = ConvertTo-SecureString $secretValue -AsPlainText -Force
$secret = Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName -SecretValue $secureValue
return $secret
# Verify
# (Get-AzKeyVaultSecret -vaultName $keyVaultName -name $secretName).SecretValueText

}