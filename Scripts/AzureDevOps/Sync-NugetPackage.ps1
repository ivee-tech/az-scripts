# . .\AzureDevOpsContext.ps1

Function Sync-NugetPackage
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$feedId,
    [Parameter(Mandatory=$true)][string]$packageName,
    [Parameter()][string]$packageVersion,
    [ValidateSet("nuget", "npm")]
    [Parameter(Mandatory=$true)][string]$protocolType,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'

if([string]::IsNullOrEmpty($packageVersion)) {
    $package = Get-FeedPackageByName -feedId $feedId -packageName $packageName -protocolType $protocolType -context $context
    $packageVersion = ($package.value[0].versions | Sort-Object -Property publishDate -Descending)[0].version
}

$packageUrl = "$($context.projectBaseUrl)/packaging/feeds/$feedId/$protocolType/packages/$packageName/versions/$packageVersion/content?api-version=$v"
Write-Host $packageUrl

if($context.isOnline) {
    $result = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $packageUrl -Method Head
}
else {
    $result = Invoke-RestMethod -Uri $packageUrl -UseDefaultCredentials -Method Head
}

return $result

}