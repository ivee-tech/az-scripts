Function Get-UserEntitlements
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)


$v = $context.apiVersion + '-preview.3'

$ctx = Get-AzureDevOpsContext -protocol https -coreServer vsaex.dev.azure.com -org $context.org -project $context.project -apiVersion $context.apiVersion `
    -pat $context.pat -isOnline

$userEntitlementsUrl = $ctx.orgBaseUrl + '/userentitlements?api-version=' + $v
Write-Output $userEntitlementsUrl

if($context.isOnline) {
    $userEntitlements = Invoke-RestMethod -Headers @{Authorization="Basic $($ctx.base64AuthInfo)"} -Uri $userEntitlementsUrl
}
else {
    $userEntitlements = Invoke-RestMethod -Uri $userEntitlementsUrl -UseDefaultCredentials
}

return $userEntitlements

}
