Function Copy-FileFromStorageAccount {
    param(
        [Parameter(Mandatory=$true)][string]$acctName,
        [Parameter(Mandatory=$true)][string]$sasToken,
        [Parameter(Mandatory=$true)][string]$containerName,
        [Parameter(Mandatory=$true)][string]$fileName,
        [Parameter(Mandatory=$true)][string]$filePath

    )

$ctx = New-AzStorageContext -StorageAccountName $acctName -SasToken $sasToken
Measure-Command {
    Get-AzStorageBlobContent -Destination $filePath -Container $containerName -Blob $fileName -Context $ctx -Force
}

}
