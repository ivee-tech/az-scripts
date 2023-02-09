# . .\AzureDevOpsContext.ps1

Function Get-SecurityNamespaces
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$secNamespacesUrl = $context.orgBaseUrl + '/securitynamespaces?api-version=' + $context.apiVersion
Write-Host $secNamespacesUrl

if($context.isOnline) {
    $securityNamespaces = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $secNamespacesUrl -Method Get
}
else {
    $securityNamespaces = Invoke-RestMethod -Uri $secNamespacesUrl -UseDefaultCredentials -Method Post
}

return $securityNamespaces

}