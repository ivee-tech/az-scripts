# . .\AzureDevOpsContext.ps1

Function Add-VarGroup
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$varGroupName,
    [Parameter()][string]$description,
    [Parameter(Mandatory=$true)][hashtable]$vars,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'
$v = $context.apiVersion + '-preview.2'

$varGroupsUrl = $context.orgBaseUrl + '/distributedtask/variablegroups?api-version=' + $v
$varGroupsUrl

$project = Get-Project -projectName $context.project -context $context

$varsData = @{}
$vars.Keys | ForEach-Object { 
    $key = $_
    $value = $vars.Item($key)
    $varsData[$key] = @{ value = $value; }
 }
$obj = @{
  variables = $varsData;
  type = "Vsts";
  name = $varGroupName;
  description = $description;
  variableGroupProjectReferences = @(
      @{
          name = $varGroupName;
          description = $description;
          projectReference = @{
              id = $project.id;
              name = $project.name;
          };
      }
  );
} 
$data = ConvertTo-Json -InputObject $obj -Depth 10

$data

if($context.isOnline) {
    $varGroup = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $varGroupsUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $varGroup = Invoke-RestMethod -Uri $varGroupsUrl -UseDefaultCredentials -Method Post -Body $data -ContentType $contentType
}

return $varGroup

}