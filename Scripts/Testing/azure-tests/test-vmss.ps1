param(
    [string]$testAssertionPath
)

# $testAssertionPath = '../Test-Assertion.ps1'
. $testAssertionPath

$rgName = 'da-devops'
$vmssName = 'davmss002'
$vmss = Get-AzVmss -ResourceGroupName $rgName -VMScaleSetName $vmssName

$expected = 'Succeeded'
$actual = $vmss.ProvisioningState
Write-Host $actual
Test-Assertion ($expected -eq $actual)

$expected = 'AustraliaEast'
$actual = $vmss.Location
Write-Host $actual
Test-Assertion ($expected -eq $actual)

$expected = '2012-R2-Datacenter'
$actual = $vmss.VirtualMachineProfile.StorageProfile.ImageReference.Sku
Write-Host $actual
Test-Assertion ($expected -eq $actual)

$expected = 'Standard_D4s_v3'
$actual = $vmss.Sku.Name
Write-Host $actual
Test-Assertion ($expected -eq $actual)

$expected = 10
$actual = $vmss.Sku.Capacity
Write-Host $actual
Test-Assertion ($expected -eq $actual)
