# . .\AzureDevOpsContext.ps1
# . .\Get-Project.ps1
Function Add-GenericServiceEndpoint
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$name,
    [Parameter(Mandatory=$true)][string]$url,
    [Parameter()][string]$userName,
    [Parameter()][string]$password,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'

$project = Get-Project -projectName $context.project -context $context

$data = @{
    name = $name;
    type = "Generic";
    url = $url;
    authorization = @{
      parameters = @{
        username = $userName;
        password = $password;
      };
      scheme = "UsernamePassword";
    };
    isShared = $false;
    isReady = $true;
    serviceEndpointProjectReferences = @(
      @{
        projectReference = @{
          id = $project.id;
          name = $project.name;
        };
        name = $name;
      }
    )
  } | ConvertTo-Json -Depth 10

$v = $context.apiVersion + '-preview.4'
$endpointsUrl = $context.orgBaseUrl + '/serviceendpoint/endpoints?api-version=' + $v

if($context.isOnline) {
    $endpoint = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $endpointsUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $endpoint = Invoke-RestMethod -Uri $endpointsUrl -UseDefaultCredentials -Method Post -Body $data -ContentType $contentType
}

return $endpoint

}