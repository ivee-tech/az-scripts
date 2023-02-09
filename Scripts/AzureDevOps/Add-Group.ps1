# . .\AzureDevOpsContext.ps1

Function Add-Group
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$name,
    [Parameter(Mandatory=$true)][string]$description,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'
$v = $context.apiVersion + '-preview.1'
$graphCtx = Get-AzureDevOpsContext -protocol https -coreServer vssps.dev.azure.com -org $context.org -project $context.project -apiVersion $context.apiVersion `
    -pat $context.pat -isOnline

$projectDescriptor = Get-ProjectDescriptor -projectName $context.project -context $context
$groupUrl = $graphCtx.orgBaseUrl + '/graph/groups?scopeDescriptor=' + $projectDescriptor.value + '&api-version=' + $v
$groupUrl

$data = @{
    displayName = $name;
    description = $description;

} | ConvertTo-Json -Depth 10

if($context.isOnline) {
    $group = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $groupUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $group = Invoke-RestMethod -Uri $groupUrl -UseDefaultCredentials -Method Post -Body $data -ContentType $contentType
}

return $group
}


