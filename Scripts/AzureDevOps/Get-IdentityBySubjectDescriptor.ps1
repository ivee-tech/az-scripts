# . .\AzureDevOpsContext.ps1

Function Get-IdentityBySubjectDescriptor
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$subjectDescriptor,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'
$graphCtx = Get-AzureDevOpsContext -protocol https -coreServer vssps.dev.azure.com -org $context.org -project $context.project -apiVersion $context.apiVersion `
    -pat $context.pat -isOnline

$descriptorUrl = $graphCtx.orgBaseUrl + '/identities?subjectDescriptors=' + $subjectDescriptor + '&api-version=' + $v
Write-Host $descriptorUrl

if($context.isOnline) {
    $descriptorObj = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $descriptorUrl -Method Get
}
else {
    $descriptorObj = Invoke-RestMethod -Uri $descriptorUrl -UseDefaultCredentials -Method Post
}

if($null -ne $descriptorObj.value -and $descriptorObj.value.length -gt 0) {
    return $descriptorObj.value[0]
}

return $null

}