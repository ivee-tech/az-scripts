param(
    [string]$testAssertionPath
)

# $testAssertionPath = '../Test-Assertion.ps1'
. $testAssertionPath

$rgName = 'da-devops'
$vmName = 'davm002'
$vm = Get-AzVM -ResourceGroupName $rgName -Name $vmName


$expected = 'Succeeded'
$actual = $vm.ProvisioningState
Write-Host $actual
Test-Assertion ($expected -eq $actual)

$expected = 'AustraliaEast'
$actual = $vm.Location
Write-Host $actual
Test-Assertion ($expected -eq $actual)

$expected = 'davm002'
$actual = $vm.OSProfile.ComputerName

$expected = 'vs-2019-comm-latest-ws2019'
$actual = $vm.StorageProfile.ImageReference.Sku
Write-Host $actual
Test-Assertion ($expected -eq $actual)

$expected = 'Standard_DS2_v2'
$actual = $vm.HardwareProfile.VmSize
Write-Host $actual
Test-Assertion ($expected -eq $actual)

$expected = 'AdminUser'
$actual = $vm.OSProfile.AdminUsername
Write-Host $actual
Test-Assertion ($expected -eq $actual)

$expected = 1
$actual = $vm.StorageProfile.DataDisks.Count
Write-Host $actual
Test-Assertion ($expected -eq $actual)

$expected = 1023
$actual = $vm.StorageProfile.DataDisks[0].DiskSizeGB
Write-Host $actual
Test-Assertion ($expected -eq $actual)
