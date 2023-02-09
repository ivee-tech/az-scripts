# . .\AzureDevOpsContext.ps1

Function Add-GitRepoBranchPolicyApprover
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$repositoryId,
    [Parameter(Mandatory=$true)][int]$minimumApproverCount,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'


$cfg = @{
    isEnabled = $true;
    isBlocking = $true;
    type = @{
      id = "fa4e907d-c16b-4a4c-9dfa-4906e5d171dd";
    };
    settings = @{
      minimumApproverCount = $minimumApproverCount;
      creatorVoteCounts = $false; # Allow requestors to approve their own changes
      allowDownvotes = $false; # Allow completion even if some reviewers vote to wait or reject
      resetOnSourcePush = $false; # Reset code reviewer votes when there are new changes
      blockLastPusherVote = $false; # Prohibit the most recent pusher from approving their own changes
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
