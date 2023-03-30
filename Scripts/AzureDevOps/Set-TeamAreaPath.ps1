# . .\AzureDevOpsContext.ps1

Function Set-TeamAreaPath
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$teamName,
    [Parameter(Mandatory=$true)][string]$areaPath,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json-patch+json'
$contentType = 'application/json'

# PATCH https://dev.azure.com/{organization}/{project}/{team}/_apis/work/teamsettings/teamfieldvalues?api-version=7.1-preview.1
$v = $context.apiVersion + '-preview.1'
$teamsUrl = $context.orgUrl + '/' + $context.project + '/' + $teamName + '/_apis/work/teamsettings/teamfieldvalues?api-version=' + $v
Write-Host $teamsUrl

$data = @{
    defaultValue = $areaPath;
    values = @(
        @{
            value = $areaPath;
            includeChildren = $true;
        }
    );
} | ConvertTo-Json -Depth 10

if($context.isOnline) {
    $team = Invoke-WebRequest -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $teamsUrl -Method Patch -Body $data -ContentType $contentType
}
else {
    $team = Invoke-WebRequest -Uri $teamsUrl -UseDefaultCredentials -Method Patch -Body $data -ContentType $contentType
}

return $team

}