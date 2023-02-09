# . .\AzureDevOpsContext.ps1

Function Get-PermissionsReports
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + "-preview.1"
$permissionsReportUrl = $context.orgBaseUrl + "/permissionsreport?api-version=" + $v
Write-Output $permissionsReportUrl

if($context.isOnline) {
    $reports = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $permissionsReportUrl
}
else {
    $reports = Invoke-RestMethod -Uri $permissionsReportUrl -UseDefaultCredentials
}

return $reports

}