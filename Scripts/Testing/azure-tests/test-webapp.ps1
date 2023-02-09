param(
    [string]$testAssertionPath
)

# $testAssertionPath = '../Test-Assertion.ps1'
. $testAssertionPath

$rgName = 'da-devops'
$appName = 'da-devops-iaac-web-99'

$app = Get-AzWebApp -ResourceGroupName $rgName -Name $appName


$expected = 'Running'
$actual = $app.State
Write-Host $actual
Test-Assertion ($expected -eq $actual)

$expected = 'Australia East'
$actual = $app.Location
Write-Host $actual
Test-Assertion ($expected -eq $actual)

$expected = $appName + '.azurewebsites.net'
$actual = $app.DefaultHostName
Write-Host $actual
Test-Assertion ($expected -eq $actual)
