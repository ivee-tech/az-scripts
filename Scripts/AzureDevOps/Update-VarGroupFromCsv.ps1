# . .\AzureDevOpsContext.ps1
Function Update-VarGroupFromCsv {
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][int]$groupId,
    [Parameter(Mandatory=$true)][string]$varGroupName,
    [Parameter()][string]$description,
    [Parameter(Mandatory=$true)][string]$csvFilePath,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)
$contentType = 'application/json'

$v = $context.apiVersion + '-preview.1'
$varGroupsUrl = $context.projectBaseUrl + '/distributedtask/variablegroups/' + $groupId + '?api-version=' + $v
$varGroupsUrl

$vars = Import-Csv -Path $csvFilePath -Header @('key', 'value')

$varsData = @{}
$vars | ForEach-Object { $index = 0 } {
    $index++
    $varsData[$_.key] = @{ value = $_.value }
}

$data = @{
    name = $varGroupName;
    variables = $varsData;
    type = "Vsts";
}
if($null -ne $description) {
    $data.description = $description
}

$body = $data | ConvertTo-Json -Depth 100
$body

if($context.isOnline) {
    $varGroup = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $varGroupsUrl -Method Put -Body $body -ContentType $contentType
}
else {
    $varGroup = Invoke-RestMethod -Uri $varGroupsUrl -UseDefaultCredentials -Method Put -Body $body -ContentType $contentType
}

return $varGroup

}