param(
    [string]$testAssertionPath
)

# $testAssertionPath = '../Test-Assertion.ps1'
. $testAssertionPath

$rgName = 'da-devops'
$svrName = 'da-devops-iaac-sql-99'
$dbName = 'da-devops-iaac-db'

$db = Get-AzSqlDatabase -ResourceGroupName $rgName -ServerName $svrName -DatabaseName $dbName

$expected = 'Online'
$actual = $db.Status
Write-Host $actual
Test-Assertion ($expected -eq $actual)

$expected = 'AustraliaEast'
$actual = $db.Location
Write-Host $actual
Test-Assertion ($expected -eq $actual)

$expected = 'Standard'
$actual = $db.SkuName
Write-Host $actual
Test-Assertion ($expected -eq $actual)

$expected = 10
$actual = $db.Capacity
Write-Host $actual
Test-Assertion ($expected -eq $actual)
