$org = 'ivee'
$pat = '***'
$b64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($org):$($pat)"))

$url = "https://vsaex.dev.azure.com/$($org)/_apis/userentitlements?top=10000&select=project&api-version=4.1-preview.1"
$response = Invoke-RestMethod -Uri $url -Method Get -Headers @{ Authorization = "Basic $b64" }  -ContentType "application/json"

$userId = '58781fb5-cca0-4437-a721-a5c76775f394'
$url = "https://vsaex.dev.azure.com/$($org)/_apis/userentitlements/$($userId)?api-version=7.1-preview.3"
$response = Invoke-RestMethod -Uri $url -Method Get -Headers @{ Authorization = "Basic $b64" }  -ContentType "application/json"
$response


$url = "https://vssps.dev.azure.com/$($org)/_apis/graph/users?api-version=7.1-preview.1"
$response = Invoke-RestMethod -Uri $url -Method Get -Headers @{ Authorization = "Basic $b64" }  -ContentType "application/json"
$response.value

# get entitlements for all users with unknown licence source
$entitlements = $response.value | Where-Object { $_.accessLevel.assignmentSource -eq 'unknown' }
$entitlements.Count

# get entitlements for specific alias
$alias = 'ibrahimsmobile@gmail.com'
$entitlements = $response.value | Where-Object { $_.user.mailAddress -eq $alias }
$entitlements.accessLevel

# UNDOCUMENTED API - MEMInternal/RemoveExplicitAssignment
$ruleOption = 0 # 1 - DRY-RUN; use 0 for full execution
$url = "https://vsaex.dev.azure.com/$($org)/_apis/MEMInternal/RemoveExplicitAssignment?select=groupRules$ruleOption=$ruleOption&api-version=5.0-preview.1"
$data = ConvertTo-Json -InputObject @($entitlements[0].id)
$data
$reaResponse = Invoke-WebRequest -Uri $url -Headers @{ Authorization = "Basic $b64" } -Method Post -Body $data -ContentType 'application/json'
$reaRsponse

# remove entitlement based on User ID
# $userIds = @('e83b9f24-d36b-44d7-bf60-55345963e577') #@($entitlements.user.originId)
$userIds = @($entitlements[0].id) # user.originId)
$userIds | ForEach-Object {
    $userId = $_
    $url = "https://vsaex.dev.azure.com/$($org)/_apis/userentitlements/$($userId)?api-version=7.1-preview.3"
    $url
    $response = Invoke-WebRequest -Uri $url -Headers @{ Authorization = "Basic $b64" } -Method Delete
    $response
}





