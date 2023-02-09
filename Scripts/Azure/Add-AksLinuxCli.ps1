Function Add-AksLinuxCli
{
param(
    [Parameter(Mandatory=$true)][string]$rgName,
    [Parameter(Mandatory=$true)][string]$location,
    [Parameter(Mandatory=$true)][string]$aksClusterName,
    [Parameter(Mandatory=$true)][int]$aksNodeCount,
    [Parameter(Mandatory=$true)][string]$aksVmSize
)

$sp = (az ad sp create-for-rbac --skip-assignment) | ConvertFrom-Json

# get the results from above and set the variables
$appId = $sp.appId
$clientSecret = $sp.password

# create AKS cluster
$cluster = (az aks create --name $aksClusterName --resource-group $rgName --node-count $aksNodeCount `
    --generate-ssh-keys --service-principal $appId --client-secret $clientSecret --location $location `
    --node-vm-size $aksVmSize) | ConvertFrom-Json

return $cluster

}
