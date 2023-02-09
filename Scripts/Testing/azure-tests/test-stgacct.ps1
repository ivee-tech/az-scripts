param(
    [string]$testAssertionPath
)

# $testAssertionPath = '../Test-Assertion.ps1'
. $testAssertionPath

$rgName = 'da-devops'
$stgAcctName = 'dadevopsiaacstgacct99'

$stgAcct = Get-AzStorageAccount -ResourceGroupName $rgName -Name $stgAcctName

$expected = 'Succeeded'
$actual = $stgAcct.ProvisioningState
Write-Host $actual
Test-Assertion ($expected -eq $actual)

$expected = 'AustraliaEast'
$actual = $stgAcct.Location
Write-Host $actual
Test-Assertion ($expected -eq $actual)

$expected1 = 'Standard_LRS'
$expected2 = 'StandardLRS'
$actual = $stgAcct.Sku.Name
Write-Host $actual
Test-Assertion (($expected1 -eq $actual) -or ($expected2 -eq $actual))

$expected = 'Storage'
$actual = $stgAcct.Kind
Write-Host $actual
Test-Assertion ($expected -eq $actual)
