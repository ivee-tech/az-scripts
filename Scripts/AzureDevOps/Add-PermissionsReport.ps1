# . .\AzureDevOpsContext.ps1

Function Add-PermissionsReport
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$reportName,
    [Parameter()][string[]]$descriptors,
    [Parameter()][PermissionsReportResource]$resource,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + "-preview.1"
$permissionsReportUrl = $context.orgBaseUrl + "/permissionsreport/" + $reportId + "?api-version=" + $v
$contentType = "application/json"
Write-Output $permissionsReportUrl

$body = @{
    descriptors = $descriptors;
    reportName = $reportName;
    resources = @($resource);
} | ConvertTo-Json -Depth 10

Write-Output $body

if($context.isOnline) {
    $result = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $permissionsReportUrl -Method Post -ContentType $contentType -Body $body
}
else {
    $result = Invoke-RestMethod -Uri $permissionsReportUrl -UseDefaultCredentials -Method Post -ContentType $contentType -Body $body
}

return $result

}
