Function Push-AcrImage {
    param(
        [Parameter(Mandatory=$true)][string]$rgName,
        [Parameter(Mandatory=$true)][string]$acrName,
        [Parameter(Mandatory=$true)][string]$imageName,
        [Parameter(Mandatory=$true)][string]$imageTag
    )

$registry = Get-AzContainerRegistry -Name $acrName -ResourceGroupName $rgName -ErrorAction SilentlyContinue

$loginServer = $registry.LoginServer

$creds = Get-AzContainerRegistryCredential -Registry $registry
$creds.Password | docker login $registry.LoginServer -u $creds.Username --password-stdin

$localImage = "$($imageName):$($imageTag)"
$remoteImage = "$($loginServer)/$($localImage)"
docker tag $localImage $remoteImage

docker push $remoteImage

}