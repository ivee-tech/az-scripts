Function Get-AllGroups
{
    [CmdletBinding()]
param(
    [Parameter()][string]$projectName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'

$graphCtx = Get-AzureDevOpsContext -protocol https -coreServer vssps.dev.azure.com -org $context.org -project $context.project -apiVersion $context.apiVersion `
    -pat $context.pat -isOnline

$useDescriptor = ![string]::IsNullOrEmpty($projectName)
if($useDescriptor) {
    $descriptor = Get-ProjectDescriptor -projectName $projectName -context $context
}
$headers = @{ Authorization = "Basic $($context.base64AuthInfo)" }
$ctHeader = 'X-MS-ContinuationToken'
$result = @{
    count = 0
    value = @()
}
$ct = $null
do {
    if($useDescriptor) {
        $groupsUrl = $graphCtx.orgBaseUrl + '/graph/groups?scopeDescriptor=' + $descriptor.value + '&continuationToken=' + $ct + '&api-version=' + $v
    }
    else {
        $groupsUrl = $graphCtx.orgBaseUrl + '/graph/groups?continuationToken=' + $ct + '&api-version=' + $v
    }
    Write-Output $groupsUrl
    $r = Invoke-WebRequest -Headers $headers -Uri $groupsUrl
    $obj = $r.Content | ConvertFrom-Json 
    $result.count += $obj.count
    $result.value += $obj.value
    $ct = $r.Headers[$ctHeader]
} while($null -ne $ct)
    
return $result

}
