Function Add-Aci {
    param(
        [Parameter(Mandatory=$true)][string]$rgName,
        [Parameter(Mandatory=$true)][string]$acrName,
        [Parameter(Mandatory=$true)][string]$location,
        [Parameter(Mandatory=$true)][string]$containerGroupName,
        [Parameter(Mandatory=$true)][string]$imageName,
        [Parameter(Mandatory=$true)][string]$imageTag,
        [Parameter(Mandatory=$true)][string]$osType,
        [Parameter()][hashtable]$envVars
    )

$registry = Get-AzContainerRegistry -Name $acrName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
$loginServer = $registry.LoginServer
$creds = Get-AzContainerRegistryCredential -Registry $registry
$secPwd = ConvertTo-SecureString $creds.Password -AsPlainText -Force
$psCreds = New-Object System.Management.Automation.PSCredential ($creds.Username, $secPwd)
$localImage = "$($imageName):$($imageTag)"
$remoteImage = "$($loginServer)/$($localImage)"
if($null -ne $envVars) {
    $container = New-AzContainerGroup -RegistryCredential $psCreds -ResourceGroupName $rgName -Location $location -Name $containerGroupName `
        -Image $remoteImage -OsType $osType -EnvironmentVariable $envVars # -DnsNameLabel $dnsLabel -Port $port
}
else {
    $container = New-AzContainerGroup -RegistryCredential $psCreds -ResourceGroupName $rgName -Location $location -Name $containerGroupName `
        -Image $remoteImage -OsType $osType # -DnsNameLabel $dnsLabel -Port $port
}

return $container

}