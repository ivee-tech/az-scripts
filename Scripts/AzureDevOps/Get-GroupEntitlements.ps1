Function Get-GroupEntitlements
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)


$v = $context.apiVersion + '-preview.1'

$ctx = Get-AzureDevOpsContext -protocol https -coreServer vsaex.dev.azure.com -org $context.org -project $context.project -apiVersion $context.apiVersion `
    -pat $context.pat -isOnline

$groupEntitlementsUrl = $ctx.orgBaseUrl + '/groupentitlements?api-version=' + $v
Write-Output $groupEntitlementsUrl

if($context.isOnline) {
    $groupEntitlements = Invoke-RestMethod -Headers @{Authorization="Basic $($ctx.base64AuthInfo)"} -Uri $groupEntitlementsUrl
}
else {
    $groupEntitlements = Invoke-RestMethod -Uri $groupEntitlementsUrl -UseDefaultCredentials
}

return $groupEntitlements

}
