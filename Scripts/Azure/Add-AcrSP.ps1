Function Add-AcrSP
{
param(
    [Parameter(Mandatory=$true)][string]$rgName,
    [Parameter(Mandatory=$true)][string]$acrName,
    [ValidateSet("AcrPull", "AcrPush", "Owner")]
    [Parameter(Mandatory=$true)][string]$acrRole
)

# Modify for your environment. The 'registryName' is the name of your Azure
# Container Registry, the 'resourceGroup' is the name of the resource group
# in which your registry resides, and the 'servicePrincipalName' can be any
# unique name within your subscription (you can use the default below).
$servicePrincipalName = "$acrName-SP-$(Get-Random)"

# Configure the secure password for the service principal
Import-Module Az.Resources # Imports the PSADPasswordCredential object
$password = [guid]::NewGuid().Guid
$secpassw = New-Object Microsoft.Azure.Commands.ActiveDirectory.PSADPasswordCredential -Property @{ StartDate=Get-Date; EndDate=Get-Date -Year 2024; Password=$password}

# Get a reference to the container registry; need its fully qualified ID
# when assigning the role to the principal in a subsequent command.
$registry = Get-AzContainerRegistry -ResourceGroupName $rgName -Name $acrName

# Create the service principal
$sp = New-AzADServicePrincipal -DisplayName $servicePrincipalName -PasswordCredential $secpassw

# Sleep a few seconds to allow the service principal to propagate throughout
# Azure Active Directory
Start-Sleep 30

# Assign the role to the service principal. Default permissions are for docker
# pull access. Modify the 'RoleDefinitionName' argument value as desired:
# acrpull:     pull only
# acrpush:     push and pull
# Owner:       push, pull, and assign roles
$role = New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName $acrRole -Scope $registry.Id

# Output the service principal's credentials; use these in your services and
# applications to authenticate to the container registry.
$result = @{
    applicationId = $sp.ApplicationId
    spName = $servicePrincipalName
    password = $password
} 

return $result
}