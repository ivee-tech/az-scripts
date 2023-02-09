Function Get-StorageAccountSAS {
    param(
        [Parameter(Mandatory=$true)][string]$rgName,
        [Parameter(Mandatory=$true)][string]$acctName,
        [Parameter(Mandatory=$true)][string]$containerName,
        [Parameter(Mandatory=$true)][decimal]$hoursValidity
    )

$storageAccount = Get-AzStorageAccount -ResourceGroupName $rgName -Name $acctName

$ctx = $storageAccount.Context

$startTime = Get-Date
$endTime = $startTime.AddHours($hoursValidity)
$sasToken = New-AzStorageContainerSASToken -Container $containerName -Permission rwdl -StartTime $startTime -ExpiryTime $endTime -Context $ctx

return $sasToken

}
