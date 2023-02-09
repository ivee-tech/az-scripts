# . .\AzureDevOpsContext.ps1

Function Set-GroupPermission {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$groupName,
        # for list of namespaces, use: az devops security permission namespace list --query "[].name"
        # for both ids and names, use: az devops security permission namespace list --query "[].{ namespaceId: namespaceId, name: name}"
        [Parameter()][string]$namespaceName,
        [Parameter()][string]$namespaceId,
        # for list of actions for a namespace, use: az devops security permission namespace list --query "[?@.name == '$namespaceName'].actions" 
        [Parameter(Mandatory = $true)][string]$actionName, 
        # Security token for the namespace, see this link for token guidance:
        # https://docs.microsoft.com/en-us/azure/devops/cli/security_tokens?view=azure-devops
        [Parameter(Mandatory = $true)][string]$securityToken, 
        [Parameter(Mandatory = $true)][bool]$toggleAllow, #  $true for allow, $false for deny
        [Parameter(Mandatory = $true)][bool]$merge, #  if $true, merge the ACE, otherwise replace
        [Parameter(Mandatory = $true)][AzureDevOpsContext]$context
    )

    $contentType = 'application/json'
    $projName = $context.project

    $namespace = Get-SecurityNamespace -namespaceName $namespaceName -namespaceId $namespaceId -context $context
    if ([String]::IsNullOrEmpty($namespaceId)) {
        $namespaceId = $namespace.namespaceId
    }
    Write-Host "namespaceId: $namespaceId"

    $group = Get-Group -projectName $projName -groupName $groupName -context $context
    # $descriptor = Get-DescriptorFromGroupDescriptor -groupDescriptor $group.descriptor # NOT WORKING???
    $identity = Get-IdentityBySubjectDescriptor -subjectDescriptor $group.descriptor -context $context
    $descriptor = $identity.descriptor

    $bit = ($namespace.actions | Where-Object { $_.name -eq $actionName }).bit

    $aceUrl = $context.orgBaseUrl + '/accesscontrolentries/' + $namespaceId + '?api-version=' + $context.apiVersion
    $aceUrl

    $data = @{
        token = $securityToken;
        merge = $merge;
        accessControlEntries = @(
            @{
                descriptor = $descriptor; # "Microsoft.TeamFoundation.Identity;$descriptor";
                allow = if($toggleAllow) {$bit} else {0};
                deny = if(!$toggleAllow) {$bit} else {0};
                extendedinfo = @{};
            }
        )
    } | ConvertTo-Json -Depth 10
    $data

    if ($context.isOnline) {
        $result = Invoke-RestMethod -Headers @{Authorization = "Basic $($context.base64AuthInfo)" } -Uri $aceUrl -Method Post -Body $data -ContentType $contentType
    }
    else {
        $result = Invoke-RestMethod -Uri $aceUrl -UseDefaultCredentials -Method Post -Body $data -ContentType $contentType
    }

    return $result
}


