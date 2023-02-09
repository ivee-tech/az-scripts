# . .\AzureDevOpsContext.ps1

Function Get-FeedPackageByName
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$feedId,
    [Parameter(Mandatory=$true)][string]$packageName,
    [Parameter(Mandatory=$true)][string]$protocolType,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'

$packageUrl = "$($context.projectBaseUrl)/packaging/feeds/$feedId/packages?protocolType=$protocolType&packageNameQuery=$packageName&api-version=$v"
Write-Host $packageUrl

if($context.isOnline) {
    $result = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $packageUrl -Method Get
}
else {
    $result = Invoke-RestMethod -Uri $packageUrl -UseDefaultCredentials -Method Get
}

return $result

}