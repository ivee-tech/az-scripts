Function Start-Build
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter()][string]$buildDefId,
    [Parameter()][string]$buildDefName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)
$contentType = 'application/json'

if([string]::IsNullOrEmpty($buildDefId)) {
    $buildDef = Get-BuildDefByName -buildDefName $buildDefName -context $context
    $buildDefId = $buildDef.id
}

$buildsUrl = $context.projectBaseUrl + '/build/builds?api-version=' + $context.apiVersion
$buildsUrl

$data = @{
    definition = @{
        id = $buildDefId;
    }
} | ConvertTo-Json -Depth 10

if($context.isOnline) {
    $response = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $buildsUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $response = Invoke-RestMethod -Uri $buildsUrl -UseDefaultCredentials -Method Post -Body $data -ContentType $contentType
}
return $response

}
