Function Copy-AzureFile
{
	<#
	.SYNOPSIS
		This function simplifies the process of uploading files to an Azure storage account. In order for this function to work you
		must have already logged into your Azure subscription with Login-AzureAccount. The file uploaded will be called the file
		name as the storage blob.
		
	.PARAMETER filePath
		The local path of the file(s) you'd like to upload to an Azure storage account container.
	
	.PARAMETER containerName
		The name of the Azure storage account container the file will be placed in.
	
	.PARAMETER rgName
		The name of the resource group the storage account is in.
	
	.PARAMETER stgAccName
		The name of the storage account the container that will hold the file is in.
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory,ValueFromPipelineByPropertyName)]
		[ValidateNotNullOrEmpty()]
		[ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
		[string]$filePath,
	
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$containerName,
	
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$rgName,
	
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$stgAccName,

		[Parameter()]
		[switch]$overwrite

	)
	process
	{
		try
		{
			$saParams = @{
				'ResourceGroup' = $rgName
				'Name' = $stgAccName
			}
			
			$scParams = @{
				'Container' = $containerName
			}
			
			$bcParams = @{
				'File' = $filePath
				'Blob' = ($filePath | Split-Path -Leaf)
			}
			
			if($overwrite) {
				Get-AzStorageAccount @saParams | Get-AzStorageContainer @scParams | Set-AzStorageBlobContent @bcParams -Force

			}
			else {
				Get-AzStorageAccount @saParams | Get-AzStorageContainer @scParams | Set-AzStorageBlobContent @bcParams
			}
		}
		catch
		{
			Write-Error $_.Exception.Message
		}
	}
}