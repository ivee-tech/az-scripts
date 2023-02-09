# . .\AzureDevOpsContext.ps1

Function Get-PermissionsReport
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$reportId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + "-preview.1"
$permissionsReportUrl = $context.orgBaseUrl + "/permissionsreport/" + $reportId + "?api-version=" + $v
Write-Output $permissionsReportUrl

if($context.isOnline) {
    $report = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $permissionsReportUrl
}
else {
    $report = Invoke-RestMethod -Uri $permissionsReportUrl -UseDefaultCredentials
}

return $report

}