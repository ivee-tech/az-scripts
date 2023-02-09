# . .\Set-KeyVaultSecret.ps1
Function Set-KeyVaultSecrets
{
param(
	[Parameter(Mandatory=$true)][string]$rgName,
	[Parameter(Mandatory=$true)][string]$keyVaultName,
	[Parameter(Mandatory=$true)][array]$secrets
)

$secrets | ForEach-Object {
	Set-KeyVaultSecret -rgName $rgName -keyVaultName $keyVaultName -secretName $_.key -secretValue $_.value
}

}