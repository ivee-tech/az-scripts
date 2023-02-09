$org = 'daradu'
$pat = '***'
$b64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($org):$($pat)"))

https://vsaex.dev.azure.com/daradu/_apis/groupentitlements?api-version=6.0-preview.1
https://vsaex.dev.azure.com/daradu/_apis/GroupEntitlements//members?api-version=6.0-preview.1

$url = "https://vssps.dev.azure.com/$($org)/_apis/graph/groups?api-version=6.0-preview.1"
$response = Invoke-RestMethod -Uri $url -Headers @{ Authorization = "Basic $b64" }

$group = $response.value | Where-Object { $_.displayName -eq 'ETSDemo-repo' }
$group._links.memberships



$subjectTypes = 'vss,aad,aadgp'
$scopeDescriptor = 'vssgp.Uy0xLTktMTU1MTM3NDI0NS0xNTQ0MzE5MDAwLTEzODI4OTkwMTEtMjc1OTI2Mjk3Mi0zNTE3NDcyMDYwLTEtMjI5MjQ1MTcyLTQxMDUxMjUxOTUtMzAwNjYwNzcwNi00MjM1OTE3NDIy' # [Web.HttpUtility]::UrlEncode($group.descriptor)
$scopeDescriptor = 'scp.MTg3MDBjNWMtNmQ1Mi00MzVkLWE0NzctMDJmY2QxYTg1ZDNj' # dawr-demo
$url = "https://vssps.dev.azure.com/$($org)/_apis/graph/users?subjectTypes=$($subjectTypes)&scopeDescriptor=$($scopeDescriptor)&api-version=6.0-preview.1"
$membership = Invoke-RestMethod -Uri $url -Headers @{ Authorization = "Basic $b64" }

$membership.value[2]

$subjectDescriptor = $group.descriptor
$direction = 'down'
$depth = 1
$url = "https://vssps.dev.azure.com/$($org)/_apis/graph/Memberships/$($subjectDescriptor)?direction=$($direction)&depth=$($depth)&api-version=6.0-preview.1"
$membership = Invoke-RestMethod -Uri $url -Headers @{ Authorization = "Basic $b64" }
$membership.value

