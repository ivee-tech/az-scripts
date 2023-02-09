# . .\AzureDevOpsContext.ps1

Function Add-GitRepoBranchPolicyBuild
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$repositoryId,
    [Parameter(Mandatory=$true)][int]$buildDefId,
    [Parameter()][string]$displayName = $null,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'


$cfg = @{
    isEnabled = $true;
    isBlocking = $true;
    type = @{
      id = "0609b952-1397-4640-95ec-e00a01b2c241";
    };
    settings = @{
      buildDefinitionId = $buildDefId;
      queueOnSourceUpdateOnly = $true;
      manualQueueOnly = $false;
      displayName = $displayName;
      validDuration = 60 * 12; # expires after 12 hours
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
