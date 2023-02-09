# . .\AzureDevOpsContext.ps1
# . .\Add-ClassificationNode.ps1

Function Add-ClassificationNodeRec
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [ValidateSet('areas', 'iterations')]
    [Parameter(Mandatory=$true)][string]$structureGroup,
    [Parameter(Mandatory=$true)][object]$obj,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

    $attrs = @{}
    if($null -ne $obj.startDate) { $attrs.startDate = $obj.startDate }
    if($null -ne $obj.finishDate) { $attrs.finishDate = $obj.finishDate }
    Add-ClassificationNode -structureGroup $structureGroup -name $obj.name -path $obj.path -attributes $attrs -context $context

    if($null -ne $obj.children) {
        $obj.children | ForEach-Object {
            Add-ClassificationNodeRec -structureGroup $structureGroup -obj $_ -context $context
        }
    }

}