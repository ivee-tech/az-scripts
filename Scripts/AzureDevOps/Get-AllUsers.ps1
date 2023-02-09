Function Get-AllUsers
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'

$graphCtx = Get-AzureDevOpsContext -protocol https -coreServer vssps.dev.azure.com -org $context.org -project $context.project -apiVersion $context.apiVersion `
    -pat $context.pat -isOnline

$headers = @{ Authorization = "Basic $($context.base64AuthInfo)" }
$ctHeader = 'X-MS-ContinuationToken'
$result = @{
    count = 0
    value = @()
}
$ct = $null
do {
    $usersUrl = $graphCtx.orgBaseUrl + '/graph/users?continuationToken=' + $ct + '&api-version=' + $v
    Write-Output $usersUrl
    $r = Invoke-WebRequest -Headers $headers -Uri $usersUrl -UseBasicParsing
    $obj = $r.Content | ConvertFrom-Json 
    $result.count += $obj.count
    $result.value += $obj.value
    $ct = $r.Headers[$ctHeader]
} while($null -ne $ct)
    
return $result

}
