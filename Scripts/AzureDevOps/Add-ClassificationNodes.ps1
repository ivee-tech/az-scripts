# . .\AzureDevOpsContext.ps1
# . .\Add-ClassificationNodeRec.ps1

Function Add-ClassificationNodes
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [ValidateSet('areas', 'iterations')]
    [Parameter(Mandatory=$true)][string]$structureGroup,
    [Parameter(Mandatory=$true)][string]$jsonFilePath,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'

$nodesUrl = $context.projectBaseUrl + '/wit/classificationnodes/' + $structureGroup + '?api-version=' + $context.apiVersion
Write-Host $nodesUrl

$json = Get-Content -Path $jsonFilePath -Raw
$obj = ConvertFrom-Json -InputObject $json

Add-ClassificationNodeRec -structureGroup $structureGroup -obj $obj -context $context

}

