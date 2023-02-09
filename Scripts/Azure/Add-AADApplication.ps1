Function Add-AADApplication
{
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][PSCustomObject]$appData,
    [Parameter(Mandatory=$true)][string]$accessToken
)

$contentType = "application/json"
$url = "https://graph.microsoft.com/v1.0/applications"
$url

$appJson = $appData | ConvertTo-Json -Depth 10
$headers = @{
    'Authorization' = 'Bearer ' + $accessToken
}

$app = Invoke-RestMethod -Uri $url -Headers $headers -Method POST -Body $appJson -ErrorAction Stop -ContentType $contentType -Verbose
return $app

}
