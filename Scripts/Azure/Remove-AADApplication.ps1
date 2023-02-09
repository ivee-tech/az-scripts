Function Remove-AADApplication
{
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$appObjectId,
    [Parameter(Mandatory=$true)][string]$accessToken
)

$url = "https://graph.microsoft.com/v1.0/applications/$appObjectId"
$url

$headers = @{
    'Authorization' = 'Bearer ' + $accessToken
}

# performs soft delete
$result = Invoke-RestMethod -Uri $url -Headers $headers -Method Delete
return $result

}