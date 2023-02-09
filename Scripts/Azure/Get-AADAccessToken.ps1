Function Get-AADAccessToken
{
param(
    [Parameter(Mandatory=$true)][string]$tenant,
    [Parameter(Mandatory=$true)][string]$graphAppId,
    [Parameter(Mandatory=$true)][string]$graphAppSecret
)

$tenantFullName = "$tenant.onmicrosoft.com"
$contentType = 'application/x-www-form-urlencoded'
$scope = "https://graph.microsoft.com/.default"
$url = 'https://login.microsoftonline.com/' + $tenantFullName + '/oauth2/v2.0/token?client_id=' + $graphAppId + '&scope=' + $scope + '&client_secret=' + $graphAppSecret + '&grant_type=access_token'
$url
$body = @{ 
    client_id = $graphAppId;
    grant_type = 'client_credentials';
    client_secret = $graphAppSecret;
    scope = $scope;
}
$result = Invoke-RestMethod -Uri $url -Method POST -ContentType $contentType -Body $body
return $result


}