# Install-Module Microsoft.Graph
# Import-Module Microsoft.Graph.Groups

$tenant = 'radudanielroyahoo'
$tenantId = '6e424d97-163d-46e9-a079-e66d12f36c6e'

# connect to the tenant using interactive login; provide required scopes
Connect-MgGraph -TenantId $tenantId -Scopes "openid, profile, email, User.ReadWrite.All, Group.ReadWrite.All"

# get the context information
$ctx = Get-MgContext
$ctx

# get the groups usign generic API
$url = 'https://graph.microsoft.com/v1.0/groups'
$groups = Invoke-GraphRequest -Uri $url
$groups.value

# get a single group usign cmdlet
$groupId = '5fe51d35-556a-43ec-86c2-e2d63428f43c' # '4a94e43f-81a6-481c-bebb-0e073648830c'
$group = Get-MgGroup -Property "id,displayName" -GroupId $groupId
$group

# get user membership using generic API
$userId = '58781fb5-cca0-4437-a721-a5c76775f394' # '378b9766-40ea-4b4d-8944-8aa903f7861c'
$url = "https://graph.microsoft.com/v1.0/users/$userId/memberOf"
$memberOf = Invoke-GraphRequest -Uri $url -Method GET
$memberOf.value

# add users to group using generic API
$groupId = '5fe51d35-556a-43ec-86c2-e2d63428f43c'
$url = "https://graph.microsoft.com/v1.0/groups/$groupId"
$userId1 = 'e78a314e-3cc2-46d4-9856-267c2992829c'
# up to 20 users; if user already added to the group, the request returns 400 Bad Request 
$data = @{
  "members@odata.bind" = @(
    "https://graph.microsoft.com/v1.0/directoryObjects/$userId1"
    # "https://graph.microsoft.com/v1.0/directoryObjects/$userId2"
    )
} | ConvertTo-Json
$response = Invoke-GraphRequest -Uri $url -Method Patch -Body $data -ContentType 'application/json'

# disconnect MsGraph session
Disconnect-MgGraph

