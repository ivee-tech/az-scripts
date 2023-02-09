[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# Install-Module Microsoft.Graph

Import-Module Microsoft.Graph.Groups

$tenant = 'radudanielroyahoo' # 'zipzappapps001dev' #.onmicrosoft.com'
$tenantId = '6e424d97-163d-46e9-a079-e66d12f36c6e' # '959b964f-660b-47cd-b5f8-a224061d95bd'
$graphAppId = '13b264bd-98a4-4ef1-9ccb-704010f3e0dd' # '44ac2cde-96dd-436d-81e9-40a9f1a17a02'
$graphAppSecret = '5XO7Q~id0RGX0YCD7oRPy21CNgkt_535ZwQQN' # 'mwk8Q~jXRabj76~-K.pkjReYTfBveDl03e92AbX2' # expires 04 Feb 2023

$thumbprint = 'A3CA07EF299D6FCBCDD4AC7A0E1B8924A7DB59DD'

# Logout-AzAccount
# Login-AzAccount -Tenant "$tenant.onmicrosoft.com"

<#
$certName = 'Microsoft.Graph.App'
$cert = New-SelfSignedCertificate -DnsName $tenant -CertStoreLocation "Cert:\CurrentUser\My" -FriendlyName $certName
$thumbprint = $cert.Thumbprint
Get-ChildItem Cert:\CurrentUser\my\$thumbprint | Export-Certificate -FilePath C:\temp\$certName.cer
#>

Connect-MgGraph -TenantId $tenantId -Scopes "openid, profile, email, User.ReadWrite.All, Group.ReadWrite.All"

Connect-MgGraph -TenantId $tenantId -ClientId $graphAppId -CertificateThumbprint $thumbprint `
    # -Scopes "User.ReadWrite.All", "Group.ReadWrite.All" #, "Application.ReadWrite.All", "Directory.AccessAsUser.All", "Directory.ReadWrite.All"

$ctx = Get-MgContext
$ctx.TenantId


$url = 'https://graph.microsoft.com/v1.0/groups'
$groups = Invoke-GraphRequest -Uri $url
$groups.value

# fails with Get-MgGroup : Could not load file or assembly 'Microsoft.Graph.Authentication, Version=1.4.2.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35' or one of its dependencies. The system cannot find the file specified.

$groupId = '5fe51d35-556a-43ec-86c2-e2d63428f43c' # '4a94e43f-81a6-481c-bebb-0e073648830c'
Get-MgGroup -Property "id,displayName" -GroupId $groupId
$url = "https://graph.microsoft.com/v1.0/groups/$groupId/getMemberGroups"
$groupMemberOf = Invoke-GraphRequest -Uri $url

$userId = '58781fb5-cca0-4437-a721-a5c76775f394' # '378b9766-40ea-4b4d-8944-8aa903f7861c'
$url = "https://graph.microsoft.com/v1.0/users/$userId/memberOf"
$memberOf = Invoke-GraphRequest -Uri $url -Method GET
$memberOf.GetType().GetProperties()
$memberOf = Get-MgUserMemberOf -UserId $userId
$memberOf.AdditionalProperties.displayName

$groupId = '5fe51d35-556a-43ec-86c2-e2d63428f43c' # '1cd5e23c-1571-4706-97b2-49f4205b0fa4' # tenant-Walks
$url = "https://graph.microsoft.com/v1.0/groups/$groupId"
# $userId1 = '28aa8df1-a6ec-41be-a521-4d9e9825ad79'
# $userId2 = '378b9766-40ea-4b4d-8944-8aa903f7861c'
$userId1 = 'e78a314e-3cc2-46d4-9856-267c2992829c' # '58781fb5-cca0-4437-a721-a5c76775f394'
# up to 20 users; if user already added to the group, the request returns 400 Bad Request 
$data = @{
  "members@odata.bind" = @(
    "https://graph.microsoft.com/v1.0/directoryObjects/$userId1"
    # "https://graph.microsoft.com/v1.0/directoryObjects/$userId2"
    )
} | ConvertTo-Json
$response = Invoke-GraphRequest -Uri $url -Method Patch -Body $data -ContentType 'application/json'


$url = 'https://graph.windows.net/contoso.onmicrosoft.com/users/$user@$tentant.onmicrosoft.com?api-version=1.5'
$method = 'PATCH'
$contentType = 'application/json'

$body = @{
    "extension_external_system_id" =  "EXT-001"
} | ConvertTo-Json -Depth 2

$cred = Get-Credential
Invoke-RestMethod -Uri $url -Method $method -Body $body -ContentType $contentType -Credential $cred

Disconnect-MgGraph


# direct API calls

$tenant = 'zipzappapps001dev' #.onmicrosoft.com'
$tenantId = '959b964f-660b-47cd-b5f8-a224061d95bd'
$graphAppId = '44ac2cde-96dd-436d-81e9-40a9f1a17a02'
$graphAppSecret = 'mwk8Q~jXRabj76~-K.pkjReYTfBveDl03e92AbX2' # expires 04 Feb 2023

$tenant = 'radudanielroyahoo' # 'zipzappapps001dev' #.onmicrosoft.com'
$tenantId = '6e424d97-163d-46e9-a079-e66d12f36c6e' # '959b964f-660b-47cd-b5f8-a224061d95bd'
$graphAppId = '13b264bd-98a4-4ef1-9ccb-704010f3e0dd' # '44ac2cde-96dd-436d-81e9-40a9f1a17a02'
$graphAppSecret = '5XO7Q~id0RGX0YCD7oRPy21CNgkt_535ZwQQN' # 'mwk8Q~jXRabj76~-K.pkjReYTfBveDl03e92AbX2' # expires 04 Feb 2023

$contentType = 'application/x-www-form-urlencoded'
$scope = 'https://graph.microsoft.com/.default'
$url = "https://login.microsoftonline.com/$tenant.onmicrosoft.com/oauth2/v2.0/token" #?client_id=$graphAppId&scope=$scope&client_secret=$graphAppSecret&grant_type=client_credentials"
$url
$body = @{ 
    client_id = $graphAppId;
    grant_type = 'client_credentials';
    client_secret = $graphAppSecret;
    scope = $scope;
}
$body 
$result = Invoke-RestMethod -Uri $url -Method POST -ContentType $contentType -Body $body

$token = $result.access_token
$headers = @{ Authorization = "Bearer $token" }
$url = "https://graph.microsoft.com/v1.0/users"
$url 
$users = Invoke-RestMethod -Uri $url -Headers $headers
$users.value[0]

$token = $result.access_token
$headers = @{ Authorization = "Bearer $token" }
$url = "https://graph.microsoft.com/v1.0/groups"
$url 
$groups = Invoke-RestMethod -Uri $url -Headers $headers
$groups.value


$token = $result.access_token
$headers = @{ Authorization = "Bearer $token" }
$userId = '58781fb5-cca0-4437-a721-a5c76775f394' # '378b9766-40ea-4b4d-8944-8aa903f7861c'
$url = "https://graph.microsoft.com/v1.0/users/$userId/memberOf"
$url 
$memberOf = Invoke-RestMethod -Uri $url -Headers $headers
$memberOf.value.displayName


$token = $result.access_token
$headers = @{ Authorization = "Bearer $token" }
$groupId = '5fe51d35-556a-43ec-86c2-e2d63428f43c' # '1cd5e23c-1571-4706-97b2-49f4205b0fa4' # tenant-Walks
$url = "https://graph.microsoft.com/v1.0/groups/$groupId"
# $userId1 = '28aa8df1-a6ec-41be-a521-4d9e9825ad79'
# $userId2 = '378b9766-40ea-4b4d-8944-8aa903f7861c'
$userId1 = '58781fb5-cca0-4437-a721-a5c76775f394'
# up to 20 users; if user already added to the group, the request returns 400 Bad Request 
$data = @{
  "members@odata.bind" = @(
    "https://graph.microsoft.com/v1.0/directoryObjects/$userId1"
    # "https://graph.microsoft.com/v1.0/directoryObjects/$userId2"
    )
} | ConvertTo-Json
$response = Invoke-RestMethod -Uri $url -Headers $headers -Method Patch -Body $data -ContentType 'application/json'


$token = $result.access_token
$headers = @{ Authorization = "Bearer $token" }
$url = "https://graph.microsoft.com/v1.0/directory/administrativeUnits"
$response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
$response.value
