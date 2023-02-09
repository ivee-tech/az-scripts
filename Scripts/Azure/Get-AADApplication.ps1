Function Get-AADApplication
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

$app = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
# the response is an array with two elements:
# app[0] - the graph Url
# app[1] - the application data
return $app

}