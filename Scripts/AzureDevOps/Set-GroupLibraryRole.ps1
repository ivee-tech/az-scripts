# . .\AzureDevOpsContext.ps1

Function Set-GroupLibraryRole
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$projectName,
    [Parameter(Mandatory=$true)][string]$groupName,
    [ValidateSet("Reader", "User", "Creator", "Administrator")]
    [Parameter(Mandatory=$true)][string]$roleName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'
$v = $context.apiVersion + '-preview.1'
$project = Get-Project -projectName $projectName -context $context
$group = Get-Group -projectName $projectName -groupName $groupName -context $context

$roleAssignmentsUrl = $context.orgBaseUrl + '/securityroles/scopes/distributedtask.library/roleassignments/resources/' + $project.id + '$0?api-version=' + $v
Write-Host $roleAssignmentsUrl

$roles = @(
    @{
        roleName = $roleName;
        userId = $group.originId; # for origin vsts; check for other origins, e.g. aad etc.
    }
) 
$data = ConvertTo-Json -InputObject $roles -Depth 10
$data

if($context.isOnline) {
    $result = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $roleAssignmentsUrl -Method Put -Body $data -ContentType $contentType
}
else {
    $result = Invoke-RestMethod -Uri $roleAssignmentsUrl -UseDefaultCredentials -Method Put -Body $data -ContentType $contentType
}

<#
# for some reasons, in the UI, there is an additional patch with empty data - not sure if needed
if($context.isOnline) {
    $result2 = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $roleAssignmentsUrl -Method Patch -Body '[]' -ContentType $contentType
}
else {
    $result2 = Invoke-RestMethod -Uri $roleAssignmentsUrl -UseDefaultCredentials -Method Patch -Body '[]' -ContentType $contentType
}
#>
return $result

}