Function Get-AADApplications
{
param(
    [Parameter(Mandatory=$true)][string]$accessToken
)

$url = "https://graph.microsoft.com/v1.0/applications"
$url

$headers = @{
    'Authorization' = 'Bearer ' + $accessToken
}
    
$apps = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
return $apps

}