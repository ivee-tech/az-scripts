Install-Module -Name Pester -Force -SkipPublisherCheck

Import-Module Pester

Function MyGetChildItem($path) {
    return Get-ChildItem -Path $path
}

Function GetMyIp() {
    $r = Invoke-RestMethod -Uri https://ifconfig.me/ip
    return $r
}

Invoke-Pester -Output Detailed .\script.example.ps1

$rgName = "DAResourceGroup"
$templatePath = '../../Templates/ARM/webapp'
$templateFile = "$templatePath/azuredeploy.json"
$templateParameterFile = "$templatePath/azuredeploy.parameters.json"
Test-AzResourceGroupDeployment -ResourceGroupName $rgName -TemplateFile $templateFile -TemplateParameterFile $templateParameterFile

# no longer working in Pester v5; there will be some similar functionality in v5.1
# Invoke-Pester -Script @{ Path = ".\azure-tests\ptest-webapp.ps1"; Parameters = @{ rgName = "DAResourceGroup"; appName  = "da-webapp-001" } }

Invoke-Pester -Output Detailed ".\azure-tests\ptest-webapp.ps1"

$d = Get-Date -Format "yyyyMMdd_HHmm"
Invoke-Pester -OutputFormat NUnitXml -OutputFile ".\ptest-webapp.$d.xml" ".\azure-tests\ptest-webapp.ps1"

Invoke-Pester -OutputFormat NUnitXml -OutputFile ".\ptest-webapp.results.xml" "$(System.DefaultWorkingDirectory)/_dawr-demo-deploy-Testing-CI/drop/testing/azure-tests/ptest-webapp.ps1"
