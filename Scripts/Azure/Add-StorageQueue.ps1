Function Add-StorageQueue
{
param(
    [Parameter(Mandatory=$true)][string]$rgName,
    [Parameter(Mandatory=$true)][string]$acctName,
    [Parameter(Mandatory=$true)][string]$queueName
)
$acct = Get-AzStorageAccount -StorageAccountName $acctName -ResourceGroupName $rgName
$ctx = $acct.Context

$queue = Get-AzStorageQueue -name $queueName -Context $ctx -ErrorAction SilentlyContinue
if(-not $queue){ 
    $queue = New-AzStorageQueue -name $queueName -Context $ctx
}

}