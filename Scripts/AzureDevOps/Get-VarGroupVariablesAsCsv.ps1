# . .\AzureDevOpsContext.ps1
# . .\Get-VarGroup.ps1

Function Get-VarGroupVariablesAsCsv
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][int]$groupId,
    [Parameter(Mandatory=$true)][string]$outputCsvFilePath,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$varGroup = Get-VarGroup -groupId $groupId -context $context
$props = Get-Member -InputObject $varGroup.variables -MemberType NoteProperty
$s = ''
foreach($prop in $props) {
    $propValue = $varGroup.variables | Select-Object -ExpandProperty $prop.Name
    $s += "$($prop.Name),""$($propValue.value)""
"
}
$s > $outputCsvFilePath
return $s

}