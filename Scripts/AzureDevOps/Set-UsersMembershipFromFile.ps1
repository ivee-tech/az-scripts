# . .\AzureDevOpsContext.ps1

Function Set-UsersMembershipFromFile 
{
    param(
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$true)][string]$projectName,
        [Parameter(Mandatory=$true)][string]$filePath,
        [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
    )

    $data = Import-Csv -Path $filePath
    # assumes the header is UserName,GroupName
    $data | ForEach-Object {
        $userName = $_.UserName
        $groupName = $_.GroupName
        Set-UserMembership -projectName $projectName -userName $userName -containerName $groupName -context $context
    }
}
