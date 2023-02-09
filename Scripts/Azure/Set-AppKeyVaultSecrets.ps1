# . .\Set-KeyVaultSecrets.ps1

Function Set-AppKeyVaultSecrets
{
    param(
        [Parameter(Mandatory=$true)][string]$rgName,
        [Parameter(Mandatory=$true)][string]$keyVaultName,
        [Parameter()][byte]$length = 24,
        [Parameter()][byte]$nonAlphaChars = 5
    )

$secrets = @()
$s = @{ key = "App-AzureAdB2C-ClientSecret"; value = [System.Web.Security.Membership]::GeneratePassword($length, $nonAlphaChars) }
$secrets += $s

$s = @{ key = "ConnectionStrings-AppConnectionFormat"; value = "Server=tcp:{0},1433;Initial Catalog={1};Persist Security Info=False;User ID={2};Password={3};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" }
$secrets += $s

$s = @{ key = "Meta-AzureAdB2C-ClientSecret"; value = [System.Web.Security.Membership]::GeneratePassword($length, $nonAlphaChars) }
$secrets += $s

$s = @{ key = "Settings-App-CustomAuthZKey"; value = [System.Web.Security.Membership]::GeneratePassword($length, $nonAlphaChars) }
$secrets += $s

$s = @{ key = "Settings-AppDBPassword"; value = [System.Web.Security.Membership]::GeneratePassword($length, $nonAlphaChars) }
$secrets += $s

$s = @{ key = "Settings-Meta-CustomAuthZKey"; value = [System.Web.Security.Membership]::GeneratePassword($length, $nonAlphaChars) }
$secrets += $s

Set-KeyVaultSecrets -rgName $rgName -keyVaultName $keyVaultName -secrets $secrets

}