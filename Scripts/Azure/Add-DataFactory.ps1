Function Add-DataFactory {
    param(
        [Parameter(Mandatory=$true)][string]$rgName,
        [Parameter(Mandatory=$true)][string]$location,
        [Parameter(Mandatory=$true)][string]$dataFactoryName
    )

    $rg = Get-AzResourceGroup -Name $rgName -Location $location -ErrorAction SilentlyContinue
    if($null -eq $rg) {
        $rg = New-AzResourceGroup -Name $rgName -Location $location
    }
    $dataFactory = Set-AzDataFactoryV2 -ResourceGroupName $rgName `
        -Location $location -Name $dataFactoryName
    return $dataFactory

}
