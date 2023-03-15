# on any VM, one-off execution for importing images
# login into the private registry (assumes az login)
az acr login -n myacr 

# import salesforcedx image into the prvate registry
az acr import -n myacr --source docker.io/salesforce/salesforcedx:latest-slim --image salesforce/salesforcedx:latest-slim

# test access from agent VM
sudo docker login -u myacr -p *** myacr.azurecr.io
sudo docker pull <image>

# set specific demand (agent VM)
export SALESFORCE=1