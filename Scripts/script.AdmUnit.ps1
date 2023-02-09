$tenantId = '6e424d97-163d-46e9-a079-e66d12f36c6e' # '959b964f-660b-47cd-b5f8-a224061d95bd'
# Microsoft.Graph.App-DAFF
$graphAppId = 'e72d0073-65e0-4044-b88c-f4eaf94b480e'
$graphAppObjId = 'db320972-807d-407f-a2ca-5368b61ad4a2'

Connect-AzureAD -TenantId $tenantId -

$upn = 'radudanielro_yahoo.com#EXT#@radudanielroyahoo.onmicrosoft.com'
$user = Get-AzureADUser -Filter "userPrincipalName eq '$($upn)'"
$user

$app = Get-AzureADApplication -ObjectId $graphAppObjId
$sp = Get-AzureADServicePrincipal -ObjectId $app.ObjectId
$sp

<#
# NOT WORKING
$unitName = 'DAFF'
$unit = Get-AzureADAdministrativeUnit | Where-Object { $_.Name -eq $unitName }
$unit
#>
$unitId = 'a397394f-a925-4be1-8ba1-1e39b3daf669' # DAFF

$roleDefinition = Get-AzureADMSRoleDefinition -Filter "displayName eq 'User Administrator'"

$scope = "/administrativeUnits/$($unitId)"
$roleAssignment = New-AzureADMSRoleAssignment -DirectoryScopeId $scope -RoleDefinitionId $roleDefinition.Id -PrincipalId $sp.ObjectId
$roleAssignment

Disconnect-AzureAD
