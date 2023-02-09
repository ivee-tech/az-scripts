# . .\AzureDevOpsContext.ps1

Function Add-ClassificationNode
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [ValidateSet('areas', 'iterations')]
    [Parameter(Mandatory=$true)][string]$structureGroup,
    [Parameter(Mandatory=$true)][string]$name,
    [Parameter()][string]$path,
    [Parameter()][hashtable]$attributes = $null,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'

$nodesUrl = $context.projectBaseUrl + '/wit/classificationnodes/' + $structureGroup + '/' + $path + '?api-version=' + $context.apiVersion
Write-Host $nodesUrl

$obj = @{
    name = $name;
    attributes = @{};
}

if($null -ne $attributes) {
    $attributes.Keys | ForEach-Object {
        $obj.attributes[$_] = $attributes[$_]
    }
}

$data = $obj | ConvertTo-Json -Depth 3

$data

if($context.isOnline) {
    $response = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $nodesUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $response = Invoke-RestMethod -Uri $nodesUrl -UseDefaultCredentials -Method Post -Body $data -ContentType $contentType
}

return $response

}

