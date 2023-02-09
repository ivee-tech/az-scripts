# . .\AzureDevOpsContext.ps1

Function Add-DeployKVRelease
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][int]$kvReleaseDefId,
    [Parameter(Mandatory=$true)][int]$kvBuildDefId,
    [Parameter(Mandatory=$true)][int]$kvBuildId,
    [Parameter()][string]$description,
    [Parameter(Mandatory=$true)][string]$resourceGroup,
    [Parameter(Mandatory=$true)][string]$location,
    [Parameter(Mandatory=$true)][string]$keyVaultName,
    [Parameter(Mandatory=$true)][string]$objectId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'
# v6.0-preview.8
$releasesUrl = $context.projectBaseUrl + '/release/releases' + '?api-version=' + $context.apiVersion
Write-Host $releasesUrl

$data = @{
    definitionId = $kvReleaseDefId;
    description = $description;
    artifacts = @(
        @{
            alias = "_kv-CI";
            instanceReference = @{
                id = $kvBuildId;
                definitionId = $kvBuildDefId;
            }
        }
    );
    isDraft = $false;
    reason = "manual";
    variables = @{
        resourceGroup = @{ value = $resourceGroup };
        location = @{ value = $location };
        keyVaultName = @{ value = $keyVaultName };
        objectId = @{ value = $objectId };
    }
} | ConvertTo-Json -Depth 100

if($context.isOnline) {
    $release = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $releasesUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $release = Invoke-RestMethod -Uri $releasesUrl -Method Post -Body $data -ContentType $contentType -UseDefaultCredentials
}
return $release

}
