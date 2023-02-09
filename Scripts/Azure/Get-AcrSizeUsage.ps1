Function Get-AcrSizeUsage
{
param(
    [Parameter(Mandatory=$true)][string]$rgName,
    [Parameter(Mandatory=$true)][string]$acrName
)

$acr = Get-AzContainerRegistry -ResourceGroupName $rgName -Name $acrName -IncludeDetail
$size = $acr.Usages | Where-Object { $_.name -eq "Size" }

return $size

}
