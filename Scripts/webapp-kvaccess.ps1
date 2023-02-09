. .\Set-WebAppKVAccess.ps1

param(
    [Parameter(Mandatory=$true)]$rgName,
    [Parameter(Mandatory=$true)]$webAppName,
    [Parameter(Mandatory=$true)]$rgNameKeyVault,
    [Parameter(Mandatory=$true)]$keyVaultName
)

Set-WebAppKVAccess -rgName $rgName -webAppName $webAppName -rgNameKeyVault $rgNameKeyVault -keyVaultName $keyVaultName
