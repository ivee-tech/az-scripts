Function Add-AcrCli
{
param(
    [Parameter(Mandatory=$true)][string]$rgName,
    [Parameter(Mandatory=$true)][string]$location,
    [Parameter(Mandatory=$true)][string]$acrName,
    [ValidateSet("Basic", "Standard", "Premium")]
    [Parameter(Mandatory=$true)][string]$sku
)

$grp = (az group show --name $rgName)
if($null -eq $grp) {
    # create group
    az group create --name $rgName --location $location
}

# create Azure Container Registry
$acr = (az acr create --name $acrName --resource-group $rgName --location $location --sku $sku) | ConvertFrom-Json

return $acr

}
