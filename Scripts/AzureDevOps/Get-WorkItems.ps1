# . .\AzureDevOpsContext.ps1

Function Get-WorkItems
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$ids,
    [Parameter()][datetime]$asOfDate,
    [Parameter()][string]$expand,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$wiUrl = $context.projectBaseUrl + "/wit/workitems?ids=$ids"
$queryString = ''
$query = @{}
if($asOfDate) { $query.asOf = $asOfDate }
if($expand) { $query.expand = $expand  }
$query.Keys | ForEach-Object {
    $queryString += $p + "&$_=$($query[$_])"
}
$wiUrl += '&api-version=' + $context.apiVersion
Write-Host $wiUrl

if($context.isOnline) {
    $result = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $wiUrl -Method Get
}
else {
    $result = Invoke-RestMethod -Uri $wiUrl -UseDefaultCredentials -Method Post
}

return $result

}