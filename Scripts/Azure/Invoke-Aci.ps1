Function Invoke-Aci {
    param(
        [Parameter(Mandatory=$true)][string]$rgName,
        [Parameter(Mandatory=$true)][string]$containerGroupName,
        [Parameter()][switch]$stop
    )

$container = Get-AzContainerGroup -ResourceGroupName $rgName -Name $containerGroupName

if($stop) {
    Invoke-AzResourceAction -ResourceId $container.Id -Action stop -Force
}
else {
    Invoke-AzResourceAction -ResourceId $container.Id -Action start -Force
}
    
}