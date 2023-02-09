$funcFiles = '.\AzureDevOps\*.ps1'
$moduleName = 'AzureDevOps'
$modulePath = ".\$moduleName.psm1"

Get-Content -Path $funcFiles | Set-Content -Path $modulePath

# optionally, import module
Remove-Module AzureDevOps
Import-Module $modulePath -Verbose
