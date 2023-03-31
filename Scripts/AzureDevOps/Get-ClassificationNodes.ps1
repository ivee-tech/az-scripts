# . .\AzureDevOpsContext.ps1

Function Get-ClassificationNodes
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [ValidateSet('areas', 'iterations')]
    [Parameter(Mandatory=$true)][string]$structureGroup,
    [Parameter()][string]$ids,
    [Parameter()][int]$depth,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

# GET https://dev.azure.com/{org}}/{project}/_apis/wit/classificationnodes?$depth=2&api-version=7.0
$v = $context.apiVersion
if([string]::IsNullOrEmpty($ids)) {
    $classificationNodesUrl = $context.orgUrl + '/' + $context.project + '/_apis/wit/classificationnodes/' + $structureGroup + '?$depth=' + $depth + '&api-version=' + $v
}
else {
    # structureGroup not required
    $classificationNodesUrl = $context.orgUrl + '/' + $context.project + '/_apis/wit/classificationnodes?ids=' + $ids + '&$depth=' + $depth + '&api-version=' + $v
}
Write-Host $classificationNodesUrl

if($context.isOnline) {
    $classificationNodes = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $classificationNodesUrl -Method Get
}
else {
    $classificationNodes = Invoke-RestMethod -Uri $classificationNodesUrl -UseDefaultCredentials -Method Post
}

return $classificationNodes

}

Function Get-LeafClassificationNodes(
    [PSCustomObject]$classificationNode
) {
    $leaves = @()
    $leaves += $classificationNode.children | Where-Object { !($_.hasChildren) }
    $classificationNode.children | Where-Object { $_.hasChildren } | ForEach-Object {
        $leaves += Get-LeafClassificationNodes -classificationNode $_
    }
    return $leaves
}
