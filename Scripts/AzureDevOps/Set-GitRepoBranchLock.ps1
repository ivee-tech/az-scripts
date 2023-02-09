# . .\AzureDevOpsContext.ps1

Function Set-GitRepoBranchLock
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$repositoryId,
    [Parameter(Mandatory=$true)][string]$branchName,
    [Parameter(Mandatory=$true)][bool]$lock, # $true for lock, $false for unlock
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'


$cfg = @{
  isLocked = $lock;
}
  
$data = ConvertTo-Json -InputObject $cfg -Depth 10

$configUrl = $context.projectBaseUrl + '/git/repositories/' + $repositoryId + '/refs?filter=' + $branchName + '&api-version=' + $context.apiVersion
Write-Host $configUrl
if($context.isOnline) {
    $response = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $configUrl -Method Patch -Body $data -ContentType $contentType
}
else {
    $response = Invoke-RestMethod -Uri $configUrl -Method Patch -Body $data -ContentType $contentType -UseDefaultCredentials
}
return $response

}
