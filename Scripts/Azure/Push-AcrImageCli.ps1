Function Push-AcrImageCli
{
param(
    [Parameter(Mandatory=$true)][string]$rgName,
    [Parameter(Mandatory=$true)][string]$acrName,
    [Parameter(Mandatory=$true)][string]$localImage,
    [Parameter(Mandatory=$true)][string]$remoteImage
)

#login into ACR (requires docker)
az acr login --name $acrName 


# tag image with loginServer
docker tag $localImage $remoteImage

# check
# docker image list

# push image to ACR
docker push $remoteImage

}