$tenantId = '6e424d97-163d-46e9-a079-e66d12f36c6e' # '959b964f-660b-47cd-b5f8-a224061d95bd'
$thumb = '0A6FC8084C08D81CA3239E4B7AA8B11DB712C9CA'
$appId = 'a1bcb8ce-d685-44c1-b590-59da70c5338a'

Connect-AzureAD -TenantId $tenantId -ApplicationId  $appId -CertificateThumbprint $thumb

$groupId = '5fe51d35-556a-43ec-86c2-e2d63428f43c'
$userId = 'e78a314e-3cc2-46d4-9856-267c2992829c'
Add-AzureADGroupMember -ObjectId $groupId -RefObjectId $userId


Disconnect-AzureAD


$tenantId = '6e424d97-163d-46e9-a079-e66d12f36c6e' # '959b964f-660b-47cd-b5f8-a224061d95bd'
$thumb = '0A6FC8084C08D81CA3239E4B7AA8B11DB712C9CA'
$appId = 'a1bcb8ce-d685-44c1-b590-59da70c5338a'
Connect-MgGraph -TenantId $tenantId -CertificateThumbprint $thumb -ClientId $appId

$groupId = '5fe51d35-556a-43ec-86c2-e2d63428f43c'
$userId = 'e78a314e-3cc2-46d4-9856-267c2992829c'
New-MgGroupMember -GroupId $groupId -DirectoryObjectId $userId

Disconnect-MgGraph

$tenantId = '6e424d97-163d-46e9-a079-e66d12f36c6e' # '959b964f-660b-47cd-b5f8-a224061d95bd'
$thumb = '0A6FC8084C08D81CA3239E4B7AA8B11DB712C9CA'
$appId = 'a1bcb8ce-d685-44c1-b590-59da70c5338a'
$clientSecret = 'GQW8Q~HDRFSIqL46w~hoxl0loJpQZ~o1RM_rwc8V'

$contentType = 'application/x-www-form-urlencoded'
$scope = "https://graph.microsoft.com/.default"
$url = "https://login.microsoftonline.com/$tenant.onmicrosoft.com/oauth2/v2.0/token"
$url
$body = @{ 
    client_id = $appId;
    grant_type = 'client_credentials';
    client_secret = $clientSecret;
    scope = $scope;
}
$body 
$result = Invoke-RestMethod -Uri $url -Method POST -ContentType $contentType -Body $body
$result

$groupId = '5fe51d35-556a-43ec-86c2-e2d63428f43c'
$userId = 'e78a314e-3cc2-46d4-9856-267c2992829c'
$token = $result.access_token
$headers = @{ Authorization = "Bearer $token" }
$url = "https://graph.microsoft.com/v1.0/groups/$groupId"
# $group = Invoke-RestMethod -Uri $url
# up to 20 users; if user already added to the group, the request returns 400 Bad Request 
$data = @{
  "members@odata.bind" = @(
    "https://graph.microsoft.com/v1.0/directoryObjects/$userId"
    )
} | ConvertTo-Json
$response = Invoke-RestMethod -Uri $url -Headers $headers -Method Patch -Body $data -ContentType 'application/json'
