# . .\AzureDevOpsContext.ps1
# . .\Get-Project.ps1

Function Get-ProjectDescriptor
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$projectName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$proj = Get-Project -projectName $projectName -context $context
$graphCtx = Get-AzureDevOpsContext -protocol https -coreServer vssps.dev.azure.com -org $context.org -project $context.project -apiVersion $context.apiVersion `
    -pat $context.pat -isOnline
$v = $context.apiVersion + '-preview.1'

$descriptorUrl = $graphCtx.orgBaseUrl + '/graph/descriptors/' + $proj.id + '?api-version=' + $v
Write-Host $projectApiUrl
if($context.isOnline) {
    $descriptor = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $descriptorUrl -Method Get
}
else {
    $descriptor = Invoke-RestMethod -Uri $descriptorUrl -Method Get -UseDefaultCredentials
}

return $descriptor

}
