# . .\AzureDevOpsContext.ps1

Function Add-GitRepoBranchPolicyComment
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$repositoryId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'


$cfg = @{
    isEnabled = $true;
    isBlocking = $true;
    type = @{
      id = "c6a1889d-b943-4856-b76f-9e46bb6b0df2";
    };
    settings = @{
      scope = @(
        @{
          repositoryId = $repositoryId;
          refName = "refs/heads/master";
          matchKind = "exact";
        }
      )
    }
  }
  
  $data = ConvertTo-Json -InputObject $cfg -Depth 10

$configUrl = $context.projectBaseUrl + '/policy/configurations?api-version=' + $context.apiVersion
Write-Host $configUrl
if($context.isOnline) {
    $response = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $configUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $response = Invoke-RestMethod -Uri $configUrl -Method Post -Body $data -ContentType $contentType -UseDefaultCredentials
}
return $response

}
