Function Add-AksAcrLinuxCli
{
param(
    [Parameter(Mandatory=$true)][string]$rgName,
    [Parameter(Mandatory=$true)][string]$location,
    [Parameter(Mandatory=$true)][string]$acrName,
    [Parameter(Mandatory=$true)][string]$aksClusterName,
    [Parameter(Mandatory=$true)][int]$aksNodeCount,
    [Parameter(Mandatory=$true)][string]$aksVmSize
)

$sp = (az ad sp create-for-rbac --skip-assignment) | ConvertFrom-Json

# get the results from above and set the variables
$appId = $sp.appId
$clientSecret = $sp.password

# get the ACR ID
$acrId = az acr show --name $acrName --resource-group $rgName --query "id" -o tsv

$role = 'AcrPull' # 'Reader'

# assign read ACR permissions to SP
az role assignment create --assignee $appId --role $role --scope $acrId

# create AKS cluster
$cluster = (az aks create --name $aksClusterName --resource-group $rgName --node-count $aksNodeCount `
    --generate-ssh-keys --service-principal $appId --client-secret $clientSecret --location $location `
    --node-vm-size $aksVmSize --attach-acr $acrName) | ConvertFrom-Json

return $cluster

}
