# . .\AzureDevOpsContext.ps1

Function Set-WIT
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$processId,
    [Parameter(Mandatory=$true)][string]$witRefName,
    [Parameter(Mandatory=$true)][hashtable]$wit,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)


$contentType = 'application/json-patch+json'

$witUrl = $context.orgBaseUrl + '/work/processes/' + $processId + '/workitemtypes/' + $witRefName + '?api-version=' + $context.apiVersion
Write-Host $witUrl

$data = ConvertTo-Json -InputObject $wit -Depth 10

if($context.isOnline) {
    $newWit = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $witUrl -Method Patch -Body $data -ContentType $contentType
}
else {
    $newWit = Invoke-RestMethod -Uri $witUrl -UseDefaultCredentials -Method Patch -Body $data -ContentType $contentType
}

return $newWit

}