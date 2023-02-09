# . .\AzureDevOpsContext.ps1

Function Add-UserProjectEntitlement {
    [CmdletBinding()]
    param(
      [ValidateNotNullOrEmpty()]
      [Parameter(Mandatory = $true)][string]$upn,
      [ValidateSet("advanced", "earlyAdopter", "express", "none", "professional", "stakeholder")]
      [Parameter(Mandatory = $true)][string]$accountLicenseType, 
      [string]$projectId = $null,
      [Parameter(Mandatory = $true, ValueFromPipeline = $true)][AzureDevOpsContext]$context
    )
  
# coreServer should be vsaex.dev.azure.com
$contentType = 'application/json'
$v = $context.apiVersion + '-preview.3'
$userEntitlementsUrl = $context.orgBaseUrl + '/userentitlements?api-version=' + $v
$userEntitlementsUrl

$data = @{
    accessLevel = @{
        accountLicenseType = $accountLicenseType
    };
    user = @{
        principalName = $upn;
        subjectKind = "user"
    };
    extensions = @(
        @{ id = "ms.feed" }
    )
}

if(![string]::IsNullOrEmpty($projectId)) {
    $data.projectEntitlements = @(
        @{ 
            group = @{
                groupType = "projectContributor"
            };
            projectRef = @{
                id = $projectId
            }
        }
    )
}

$body = $data | ConvertTo-Json -Depth 100
Write-Host $body

if($context.isOnline) {
    $response = Invoke-RestMethod -Headers @{Authorization = "Basic $($context.base64AuthInfo)" } -Uri $userEntitlementsUrl -Body $body -Method POST -ContentType $contentType
    Write-Host "User entitlement created successfully for UPN $upn and project reference $projectId."
    Write-Host $response
    return $response
}
else {
    Write-Host 'This cmdlet works only with Azure DevOps Services.'
    return $null
}

}
