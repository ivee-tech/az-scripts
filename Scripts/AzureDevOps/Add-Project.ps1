# . .\AzureDevOpsContext.ps1

Function Add-Project
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$name,
    [Parameter(Mandatory=$true)][string]$description,
    [Parameter(Mandatory=$true)][string]$processTemplateId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'

$projectsUrl = $context.orgBaseUrl + '/projects?api-version=' + $context.apiVersion
Write-Host $projectsUrl

$data = @{
    name = $name;
    description = $description;
    capabilities = @{
        versioncontrol = @{
          sourceControlType = "Git";
        };
        processTemplate = @{
          templateTypeId = $processTemplateId
        }
    }
} | ConvertTo-Json -Depth 100

if($context.isOnline) {
    $project = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $projectsUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $project = Invoke-RestMethod -Uri $projectsUrl -UseDefaultCredentials -Method Post -Body $data -ContentType $contentType
}

return $project

}