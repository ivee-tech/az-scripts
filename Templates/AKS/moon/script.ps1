kubectl config set-context auto-testing-aks
kubectl config current-context

git clone https://github.com/aerokube/moon-deploy.git

kubectl apply -f .\moon-deploy\moon.yaml


$rgName = 'auto-testing'
$aksClusterName = 'auto-testing-aks'
az aks get-upgrades --resource-group $rgName --name $aksClusterName
