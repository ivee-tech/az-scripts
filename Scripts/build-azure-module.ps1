$funcFiles = '.\Azure\*.ps1'
$moduleName = 'Azure'
$modulePath = ".\$moduleName.psm1"

Get-Content -Path $funcFiles | Set-Content -Path $modulePath

# optionally, import module
Import-Module $modulePath -Verbose
