# . .\AzureDevOpsContext.ps1

Function Add-AspNetCoreGitRepoStructure
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$repoName,
    [Parameter(Mandatory=$true)][string]$appName,
    [Parameter(Mandatory=$true)][string]$srcDir,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$currentLocation = Get-Location

$projectGitUrl = $context.projectUrl + '/_git/'
$repoUrl = $projectGitUrl + $repoName

$dirName = $srcDir # [System.IO.Path]::Combine($rootFolder, $customerTenant, $repoName)
$dir = Get-Item $dirName -ErrorAction SilentlyContinue

if($null -ne $dir) {
    Write-Host 'Folder ' $dirName ' already exists.'
}
else {
    $cmd = '
md ' + $dirName
    Invoke-Expression $cmd

    Copy-Item -Path '../.gitignore' -Destination $dirName
    Copy-Item -Path '../readme.md' -Destination $dirName

    $cmd = '
cd ' + $dirName + '
git init
'
    Invoke-Expression $cmd

    $cmd = '
git add .
git commit -m "Initial commit"
git remote add origin ' + $repoUrl + '
dotnet new webapp --name ' + $appName + '
git add .
git commit -m "Added webapp"
git push origin master
'

    Invoke-Expression $cmd


}

Set-Location $currentLocation

}


# . .\AzureDevOpsContext.ps1

Function Add-BuildDef
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][PSCustomObject]$def,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'

$buildDefsUrl = $context.projectBaseUrl + '/build/definitions?api-version=' + $context.apiVersion
Write-Host $projectsUrl

$data = $def | ConvertTo-Json -Depth 10

if($context.isOnline) {
    $buildDef = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $buildDefsUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $buildDef = Invoke-RestMethod -Uri $buildDefsUrl -UseDefaultCredentials -Method Post -Body $data -ContentType $contentType
}

return $buildDef

}
# . .\AzureDevOpsContext.ps1

Function Add-ClassificationNode
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [ValidateSet('areas', 'iterations')]
    [Parameter(Mandatory=$true)][string]$structureGroup,
    [Parameter(Mandatory=$true)][string]$name,
    [Parameter()][string]$path,
    [Parameter()][hashtable]$attributes = $null,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'

$nodesUrl = $context.projectBaseUrl + '/wit/classificationnodes/' + $structureGroup + '/' + $path + '?api-version=' + $context.apiVersion
Write-Host $nodesUrl

$obj = @{
    name = $name;
    attributes = @{};
}

if($null -ne $attributes) {
    $attributes.Keys | ForEach-Object {
        $obj.attributes[$_] = $attributes[$_]
    }
}

$data = $obj | ConvertTo-Json -Depth 3

$data

if($context.isOnline) {
    $response = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $nodesUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $response = Invoke-RestMethod -Uri $nodesUrl -UseDefaultCredentials -Method Post -Body $data -ContentType $contentType
}

return $response

}

# . .\AzureDevOpsContext.ps1
# . .\Add-ClassificationNode.ps1

Function Add-ClassificationNodeRec
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [ValidateSet('areas', 'iterations')]
    [Parameter(Mandatory=$true)][string]$structureGroup,
    [Parameter(Mandatory=$true)][object]$obj,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

    $attrs = @{}
    if($null -ne $obj.startDate) { $attrs.startDate = $obj.startDate }
    if($null -ne $obj.finishDate) { $attrs.finishDate = $obj.finishDate }
    Add-ClassificationNode -structureGroup $structureGroup -name $obj.name -path $obj.path -attributes $attrs -context $context

    if($null -ne $obj.children) {
        $obj.children | ForEach-Object {
            Add-ClassificationNodeRec -structureGroup $structureGroup -obj $_ -context $context
        }
    }

}
# . .\AzureDevOpsContext.ps1
# . .\Add-ClassificationNodeRec.ps1

Function Add-ClassificationNodes
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [ValidateSet('areas', 'iterations')]
    [Parameter(Mandatory=$true)][string]$structureGroup,
    [Parameter(Mandatory=$true)][string]$jsonFilePath,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'

$nodesUrl = $context.projectBaseUrl + '/wit/classificationnodes/' + $structureGroup + '?api-version=' + $context.apiVersion
Write-Host $nodesUrl

$json = Get-Content -Path $jsonFilePath -Raw
$obj = ConvertFrom-Json -InputObject $json

Add-ClassificationNodeRec -structureGroup $structureGroup -obj $obj -context $context

}

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
# . .\AzureDevOpsContext.ps1
# . .\Get-Feed.ps1

Function Add-Feed
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$name,
    [Parameter(Mandatory=$true)][string]$description,
    [Parameter()][switch]$orgLevel,
    [Parameter()][switch]$addPublicUpstreamSources,
    [Parameter()][switch]$addInternalUpstreamSource,
    [Parameter()][string]$internalFeedId,
    [Parameter()][switch]$orgLevelInternal,
    [Parameter(Mandatory=$true)][string]$orgId,
    [Parameter()][string]$projectId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'
$v = $context.apiVersion + '-preview.1'

if($addInternalUpstreamSource) {
    if($orgLevelInternal) {
        $internalFeed = Get-Feed -feedId $internalFeedId -orgLevel -context $context
    }
    else {
        $internalFeed = Get-Feed -feedId $internalFeedId -context $context
    }
}

if($orgLevel) {
    $feedsUrl = $context.orgBaseUrl + '/packaging/feeds?api-version=' + $v
}
else {
    $feedsUrl = $context.projectBaseUrl + '/packaging/feeds?api-version=' + $v
}
Write-Host $feedsUrl

$feed = @{
    name = $name;
    description = $description;
    upstreamSources = @();
}

if($addPublicUpstreamSources) {
    $feed.upstreamSources = @(
        @{
            name = "NuGet Gallery";
            protocol = "nuget";
            location = "https://api.nuget.org/v3/index.json";
            displayLocation = "https://api.nuget.org/v3/index.json";
            upstreamSourceType = "public";
        },
        @{
            name = "npmjs";
            protocol = "npm";
            location = "https://registry.npmjs.org/";
            displayLocation = "https://registry.npmjs.org/";
            upstreamSourceType = "public";
        },
        @{
            name = "Maven Central";
            protocol = "Maven";
            location = "https://repo.maven.apache.org/maven2/";
            displayLocation = "https://repo.maven.apache.org/maven2/";
            upstreamSourceType = "public";
        }
     )
}

if($addInternalUpstreamSource) {
    $internalFeed.upstreamSources | ForEach-Object {
        $us = $_
        $displayLoc = if($orgLevelInternal) { "azure-feed://$($context.org)/$internalFeedId@Local" } else { "azure-feed://$($context.org)/$($context.project)/$internalFeedId@Local" } 
        $loc = if($orgLevelInternal) { "azure-feed://$orgId/$($internalFeed.id)@$($internalFeed.defaultViewId)" } else { "azure-feed://$orgId/$projectId/$($internalFeed.id)@$($internalFeed.defaultViewId)" } 
        $feed.upstreamSources += @{
            name = "$($internalFeed.name)@Local";
            location = $loc;
            displayLocation = $displayLoc;
            protocol = $us.protocol;
            internalUpstreamCollectionId = $orgId;
            internalUpstreamFeedId = $internalFeed.id;
            internalUpstreamViewId = $internalFeed.defaultViewId;
            upstreamSourceType = "internal";
        }
    }
}

$data = ConvertTo-Json -InputObject $feed -Depth 100
Write-Host $data

if($context.isOnline) {
    $feed = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $feedsUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $feed = Invoke-RestMethod -Uri $feedsUrl -UseDefaultCredentials -Method Post -Body $data -ContentType $contentType
}

return $feed

}
# . .\AzureDevOpsContext.ps1

Function Add-Field
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$name,
    [Parameter()][string]$description,
    [ValidateSet(
        'boolean',	
        'dateTime',	
        'double',
        'guid',	
        'history',	
        'html',	
        'identity',	
        'integer',	
        'picklistDouble',	
        'picklistInteger',	
        'picklistString',	
        'plainText',	
        'string',	
        'treePath'
    )]
    [Parameter(Mandatory=$true)][string]$type,
    [Parameter()][switch]$isIdentity,
    [Parameter()][switch]$isPicklist,
    [Parameter()][switch]$isQueryable,
    [Parameter()][string]$picklistId,
    [Parameter()][switch]$readOnly,
    [Parameter()][switch]$canSortBy,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

# POST https://dev.azure.com/{organization}/{project}/_apis/wit/fields?api-version=6.1-preview.2

$v = $context.apiVersion + '-preview.2'
$fieldsUrl = $context.projectBaseUrl + '/wit/fields?api-version=' + $v
$fieldsUrl

$data = @{
    name = $name
    description = $description
    type = $type
    referenceName = "Custom.$($name)"
    usage = "workItem"
}
if($isIdentity) { $data.isIdentity = $true }
if($isPicklist) { 
    $data.isPicklist = $true 
    $data.picklistId = $picklistId
}
if($isQueryable) { $data.isQueryable = $true }
if($canSortBy) { $data.canSortBy = $true }
if($readOnly) { $data.readOnly = $true }

$contentType = 'application/json'
$body = $data | ConvertTo-Json -Depth 10

if($context.isOnline) {
    $field = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $fieldsUrl -Method Post -Body $body -ContentType $contentType
}
else {
    $field = Invoke-RestMethod -Uri $fieldsUrl -UseDefaultCredentials -Method Post -Body $body -ContentType $contentType
}

return $field

}
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
# . .\AzureDevOpsContext.ps1

Function Add-GitRepo
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$repoName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'

$projectApiUrl = $context.orgBaseUrl + '/projects/' + $context.project + '?api-version=' + $context.apiVersion
Write-Host $projectApiUrl
if($context.isOnline) {
    $projectResponse = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $projectApiUrl -Method Get
}
else {
    $projectResponse = Invoke-RestMethod -Uri $projectApiUrl -Method Get -UseDefaultCredentials
}

$projectId = $projectResponse.id
$data = '{
  "name": "' + $repoName + '",
  "project": {
    "name": "' + $context.project + '",
    "id": "' + $projectId + '"
  }
}
'
$repo = @{
    name = $repoName;
    project = @{
        name = $context.project;
        id = $projectId;
    }
}
$data = $repo | ConvertTo-Json

$gitRepoUrl = $context.projectBaseUrl + '/git/repositories?api-version=' + $context.apiVersion
Write-Host $gitRepoUrl
if($context.isOnline) {
    $repoResponse = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $gitRepoUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $repoResponse = Invoke-RestMethod -Uri $gitRepoUrl -Method Post -Body $data -ContentType $contentType -UseDefaultCredentials
}
$repoResponse

}
# . .\AzureDevOpsContext.ps1

Function Add-GitRepoBranch
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$repoName,
    [Parameter(Mandatory=$true)][string]$srcDir,
    [Parameter(Mandatory=$true)][string]$folderName,
    [Parameter(Mandatory=$true)][string]$branchName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$currentLocation = Get-Location

$projectGitUrl = $context.projectUrl + '/_git/'
$repoUrl = $projectGitUrl + $repoName

$dirName = [System.IO.Path]::Combine($srcDir, $folderName, $branchName)
$dir = Get-Item $dirName -ErrorAction SilentlyContinue

if($null -ne $dir) {
    Write-Host 'Folder ' $dirName ' already exists.'
}
else {
    $cmd = '
md ' + $dirName
    Invoke-Expression $cmd

    $cmd = '
cd ' + $dirName + '
git clone ' + $repoUrl + ' ' + $dirName + '
git checkout -b ' + $folderName + '/' + $branchName + '
'
    Invoke-Expression $cmd

    $cmd = '
git add .
git commit -m "New branch commit"
git push origin ' + $folderName + '/' + $branchName + '
'

    Invoke-Expression $cmd


}

Set-Location $currentLocation

}
# . .\AzureDevOpsContext.ps1

Function Add-GitRepoBranchPermissions
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$repoName,
    [Parameter(Mandatory=$true)][string]$tfDirPath,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

    $currentLocation = Get-Location

    try {

    $coll = $context.orgUrl + '/'

    $cmd = 'cd "' + $tfDirPath + '"' + `

    ' && tf git permission /deny:CreateBranch /group:[' + $context.project + ']\Contributors /collection:' + $coll + ' /teamproject:' + $context.project + ' /repository:' + $repoName + `

    ' && tf git permission /allow:CreateBranch /group:[' + $context.project + ']\Contributors /collection:' + $coll + ' /teamproject:' + $context.project + ' /repository:' + $repoName + ' /branch:features' + `

    ' && tf git permission /allow:CreateBranch /group:[' + $context.project + ']\Contributors /collection:' + $coll + ' /teamproject:' + $context.project + ' /repository:' + $repoName + ' /branch:users' + `

    ' && tf git permission /allow:CreateBranch /group:"[' + $context.project + ']\Project Administrators" /collection:' + $coll + ' /teamproject:' + $context.project + ' /repository:' + $repoName + ' /branch:releases' + `

    ' && tf git permission /allow:CreateBranch /group:"[' + $context.project + ']\Project Administrators" /collection:' + $coll + ' /teamproject:' + $context.project + ' /repository:' + $repoName + ' /branch:master'

    Write-Host $cmd
    # Invoke-Expression $cmd
    Start-Process "cmd" -ArgumentList "/k $cmd"

    }
    catch {
        Write-Host $_
    }

    Set-Location $currentLocation

}

# . .\AzureDevOpsContext.ps1

Function Add-GitRepoBranchPolicy
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][PSCustomObject]$policy,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'
$data = ConvertTo-Json -InputObject $policy -Depth 10

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
# . .\AzureDevOpsContext.ps1

Function Add-GitRepoBranchPolicyComment
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$repositoryId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'


$cfg = @{
    isEnabled = $true;
    isBlocking = $true;
    type = @{
      id = "c6a1889d-b943-4856-b76f-9e46bb6b0df2";
    };
    settings = @{
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
# . .\AzureDevOpsContext.ps1

Function Add-GitRepoStructure
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$repoName,
    [Parameter(Mandatory=$true)][string]$upstreamRepoUrl,
    [Parameter(Mandatory=$true)][string]$customerTenant,
    [Parameter(Mandatory=$true)][string]$rootFolder,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$currentLocation = Get-Location

$projectGitUrl = $context.projectUrl + '/_git/'
$repoUrl = $projectGitUrl + $repoName

$dirName = [System.IO.Path]::Combine($rootFolder, $customerTenant, $repoName)
$dir = Get-Item $dirName -ErrorAction SilentlyContinue

if($null -ne $dir) {
    Write-Host 'Folder ' $dirName ' already exists.'
}
else {
    $cmd = '
md ' + $dirName
    Invoke-Expression $cmd

    Copy-Item -Path '../.gitignore' -Destination $dirName
    Copy-Item -Path '../readme.md' -Destination $dirName

    $cmd = '
cd ' + $dirName + '
git init
'
    Invoke-Expression $cmd

    $cmd = '
git add .
git commit -m "Initial commit"
git remote add origin ' + $repoUrl + '
git remote add upstream ' + $upstreamRepoUrl + '
git config remote.upstream.pushurl "NA"

git pull upstream master --allow-unrelated-histories
git push origin master
'

    Invoke-Expression $cmd

    Set-Location $currentLocation

}

}


# . .\AzureDevOpsContext.ps1

Function Add-Group
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$name,
    [Parameter(Mandatory=$true)][string]$description,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'
$v = $context.apiVersion + '-preview.1'
$graphCtx = Get-AzureDevOpsContext -protocol https -coreServer vssps.dev.azure.com -org $context.org -project $context.project -apiVersion $context.apiVersion `
    -pat $context.pat -isOnline

$projectDescriptor = Get-ProjectDescriptor -projectName $context.project -context $context
$groupUrl = $graphCtx.orgBaseUrl + '/graph/groups?scopeDescriptor=' + $projectDescriptor.value + '&api-version=' + $v
$groupUrl

$data = @{
    displayName = $name;
    description = $description;

} | ConvertTo-Json -Depth 10

if($context.isOnline) {
    $group = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $groupUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $group = Invoke-RestMethod -Uri $groupUrl -UseDefaultCredentials -Method Post -Body $data -ContentType $contentType
}

return $group
}


# . .\AzureDevOpsContext.ps1

Function Add-GroupAzDevOpsCli
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$name,
    [Parameter(Mandatory=$true)][string]$description,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$currentLocation = Get-Location

Set-Location $env:USERPROFILE

az devops security group create --project "$($context.project)" --name "$name" --description "$description"

Set-Location $currentLocation

}


# . .\AzureDevOpsContext.ps1

Function Add-PermissionsReport
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$reportName,
    [Parameter()][string[]]$descriptors,
    [Parameter()][PermissionsReportResource]$resource,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + "-preview.1"
$permissionsReportUrl = $context.orgBaseUrl + "/permissionsreport/" + $reportId + "?api-version=" + $v
$contentType = "application/json"
Write-Output $permissionsReportUrl

$body = @{
    descriptors = $descriptors;
    reportName = $reportName;
    resources = @($resource);
} | ConvertTo-Json -Depth 10

Write-Output $body

if($context.isOnline) {
    $result = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $permissionsReportUrl -Method Post -ContentType $contentType -Body $body
}
else {
    $result = Invoke-RestMethod -Uri $permissionsReportUrl -UseDefaultCredentials -Method Post -ContentType $contentType -Body $body
}

return $result

}
# . .\AzureDevOpsContext.ps1

Function Add-ProcessWITField
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$processId,
    [Parameter(Mandatory=$true)][string]$witRefName,
    [Parameter(Mandatory=$true)][string]$referenceName,
    [Parameter()][string[]]$allowedValues,
    [Parameter()][string]$defaultValue,
    [Parameter()][switch]$required,
    [Parameter()][switch]$readOnly,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

# POST https://dev.azure.com/{organization}/_apis/work/processes/{processId}/workItemTypes/{witRefName}/fields?api-version=6.1-preview.2

$v = $context.apiVersion + '-preview.2'
$fieldsUrl = $context.orgBaseUrl + '/work/processes/' + $processId + '/workItemTypes/' + $witRefName + '/fields?api-version=' + $v
$fieldsUrl

$data = @{
    referenceName = $referenceName
}
if($required) { $data.required = $true }
if($readOnly) { $data.readOnly = $true }
if(![string]::IsNullOrEmpty($defaultValue)) { $data.defaultValue = $defaultValue }
if($allowedValues.Count -gt 0) { $data.allowedValues = $allowedValues }

$contentType = 'application/json'
$body = $data | ConvertTo-Json -Depth 10

if($context.isOnline) {
    $field = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $fieldsUrl -Method Post -Body $body -ContentType $contentType
}
else {
    $field = Invoke-RestMethod -Uri $fieldsUrl -UseDefaultCredentials -Method Post -Body $body -ContentType $contentType
}

return $field

}
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
# . .\AzureDevOpsContext.ps1

Function Add-ReleaseDef
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][PSCustomObject]$def,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'

$releasesDefUrl = $context.projectBaseUrl + '/release/definitions?api-version=' + $context.apiVersion
Write-Host $releasesDefUrl

$data = $def | ConvertTo-Json -Depth 10

if($context.isOnline) {
    $releaseDef = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $releasesDefUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $releaseDef = Invoke-RestMethod -Uri $releasesDefUrl -UseDefaultCredentials -Method Post -Body $data -ContentType $contentType
}

return $releaseDef

}
# . .\AzureDevOpsContext.ps1

Function Add-TaskGroup
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][PSCustomObject]$taskGroup,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'
$v = $context.apiVersion + '-preview.1'

$taskGroupsUrl = $context.projectBaseUrl + '/distributedtask/taskgroups?api-version=' + $v
$taskGroupsUrl

$data = ConvertTo-Json -InputObject $taskGroup -Depth 10

if($context.isOnline) {
    $taskGroup = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $taskGroupsUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $taskGroup = Invoke-RestMethod -Uri $taskGroupsUrl -UseDefaultCredentials -Method Post -Body $data -ContentType $contentType
}

return $taskGroup

}
# . .\AzureDevOpsContext.ps1

Function Add-Team
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$name,
    [Parameter(Mandatory=$true)][string]$description,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'

$teamsUrl = $context.orgBaseUrl + '/projects/' + $context.project + '/teams?api-version=' + $context.apiVersion
Write-Host $projectsUrl

$data = @{
    name = $name;
    description = $description;
} | ConvertTo-Json -Depth 10

if($context.isOnline) {
    $team = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $teamsUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $team = Invoke-RestMethod -Uri $teamsUrl -UseDefaultCredentials -Method Post -Body $data -ContentType $contentType
}

return $team

}
# . .\AzureDevOpsContext.ps1

Function Add-UniversalPackage
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$packageName,
    [Parameter()][string]$packageDescription,
    [Parameter(Mandatory=$true)][string]$feedId, # name or ID
    [Parameter(Mandatory=$true)][string]$packagePath,
    [Parameter(Mandatory=$true)][string]$packageVersion, # use semantic version, i.e. 1.0.0
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$currentLocation = Get-Location

Set-Location $env:USERPROFILE

az artifacts universal publish --feed $feedId `
    --name $packageName `
    --path $packagePath `
    --version $packageVersion `
    --description "$packageDescription" `
    --detect true `
    --organization $context.orgUrl

Set-Location $currentLocation

}


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
# . .\AzureDevOpsContext.ps1

Function Add-VarGroupFromCsv
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$varGroupName,
    [Parameter(Mandatory=$true)][string]$csvFilePath,
    [Parameter()][string]$description,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'
$v = $context.apiVersion + '-preview.1'
$varGroupsUrl = $context.projectBaseUrl + '/distributedtask/variablegroups?api-version=' + $v
$varGroupsUrl

$vars = Import-Csv -Path $csvFilePath -Header @('key', 'value')

$varsData = @{}
$vars | ForEach-Object { $index = 0 } {
    $index++
    $varsData[$_.key] = @{ value = $_.value }
}

$data = @{
  variables = $varsData;
  type = "Vsts";
  name = $varGroupName;
}
if($null -ne $description) {
    $data.description = $description
}

$body = $data | ConvertTo-Json -Depth 100
$body

if($context.isOnline) {
    $varGroup = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $varGroupsUrl -Method Post -Body $body -ContentType $contentType
}
else {
    $varGroup = Invoke-RestMethod -Uri $varGroupsUrl -UseDefaultCredentials -Method Post -Body $body -ContentType $contentType
}

return $varGroup

}
# . .\AzureDevOpsContext.ps1

Function Add-YamlPipeline
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$name,
    [Parameter(Mandatory=$true)][string]$description,
    [Parameter(Mandatory=$true)][string]$repoName,
    [Parameter(Mandatory=$true)][string]$yamlPath,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$currentLocation = Get-Location

Set-Location $env:USERPROFILE

$repoUrl = $context.protocol + '://' + $context.org + '@' + $context.coreServer + '/' + $context.org + '/' + $context.project + '/_git/' + $repoName
$repoUrl

az pipelines create `
    --name $name `
    --description $description `
    --repository $repoUrl `
    --branch master `
    --yml-path $yamlPath `
    --repository-type tfsgit `
    --organization $context.orgUrl `
    --project $context.project `
    --detect true

Set-Location $currentLocation

}


class AzureDevOpsContext {
    [string]$protocol
    [string]$coreServer
    [string]$org
    [string]$project
    [string]$apiVersion
    [bool]$isOnline
    [string]$pat

    [string]$orgBaseUrl
    [string]$orgUrl
    [string]$projectBaseUrl
    [string]$projectUrl
    [string]$base64AuthInfo
}
Function Backup-GitRepo {
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory = $true)][string]$backupsPath,
        [Parameter(Mandatory = $true)][string]$repoName,
        [Parameter()][switch]$archive,
        [Parameter(Mandatory = $true)][AzureDevOpsContext]$context
    )


    $orig = Get-Location

    $d = Get-Date -Format "yyyyMMdd_HHmm"
    $repoBackupsPath = [IO.Path]::Combine("$backupsPath", "$($context.org)", "$($context.project)", $repoName)
    $repoBackupPath = Join-Path -Path $repoBackupsPath -ChildPath $d
    if(!(Test-Path $repoBackupPath))
    {
        mkdir $repoBackupPath
    }

    Set-Location $repoBackupPath

    $repoUrl = $context.protocol + "://" + $context.org + "@dev.azure.com/" + $context.org + "/" + $context.project + "/_git/" + $repoName

    git clone --mirror $repoUrl

    if($archive) {
        $zipFilePath = Join-Path -Path $repoBackupPath -ChildPath "$d.zip"
        Compress-Archive -Path $repoBackupPath -DestinationPath $zipFilePath
    }

    Set-Location $orig

    return @{
        repoBackupsPath = $repoBackupsPath;
        repoBackupPath = $repoBackupPath;
        archive = $archive;
        repoUrl = $repoUrl;
        repoName = $repoName;
        zipFileName = if($archive) {"$d.zip"} else {""};
        zipFilePath = if($archive) {$zipFilePath} else {""};
    }
}
Function Build-Signature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource) {
    $xHeaders = "x-ms-date:" + $date
    $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource
  
    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $sharekeyDecoded = $sharedKey # ConvertFrom-SecureString -SecureString $sharedKey -AsPlainText
    $keyBytes = [Convert]::FromBase64String($sharekeyDecoded)
  
    $sha256 = New-Object System.Security.Cryptography.HMACSHA256
    $sha256.Key = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($calculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $customerId, $encodedHash
    return $authorization
}


# . .\AzureDevOpsContext.ps1

Function Copy-BuildDefinition
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$buildPath,
    [Parameter(Mandatory=$true)][int]$buildDefId,
    [Parameter(Mandatory=$true)][string]$buildDefName,
    [Parameter(Mandatory=$true)][string]$repoName,
    [Parameter(Mandatory=$true)][string]$varGroupName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$srcCtx,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$destCtx
)


$srcVersion = $srcCtx.apiVersion
$destVersion = $destCtx.apiVersion + '-preview.1'

$destProjListUrl = $destCtx.orgBaseUrl + '/projects?api-version=' + $destVersion
if($destCtx.isOnline) {
    $destProjList = Invoke-RestMethod -Headers @{Authorization="Basic $($destCtx.base64AuthInfo)"} -Uri $destProjListUrl
}
else {
    $destProjList = Invoke-RestMethod -Uri $destProjListUrl -UseDefaultCredentials
}
$destProjObj = $destProjList.value | Where-Object{$_.name -eq $destCtx.project } # | ConvertTo-Json

$varGroupsUrl = $destCtx.projBaseUrl + '/distributedtask/variablegroups/?groupName=' + $varGroupName + '&api-version=' + $destVersion
if($destCtx.isOnline) {
    $varGroups = Invoke-RestMethod -Headers @{Authorization="Basic $($destCtx.base64AuthInfo)"} -Uri $varGroupsUrl -Method Get
}
else {
    $varGroups = Invoke-RestMethod -Uri $varGroupsUrl -UseDefaultCredentials -Method Get
}
$varGroups
$varGroup = $varGroups.value # | Where-Object { $_ -eq $varGroupName }
$varGroup

$buildGetUrl = $srcCtx.projBaseUrl + '/build/definitions/' + $buildDefId + '?api-version=' + $srcVersion
$buildGetUrl
if($srcCtx.isOnline) {
    $buildDef = Invoke-RestMethod -Headers @{Authorization="Basic $($srcCtx.base64AuthInfo)"} -Uri $buildGetUrl
}
else {
    $buildDef = Invoke-RestMethod -Uri $buildGetUrl -UseDefaultCredentials
}

$gitRepoUrl = $destCtx.projBaseUrl + '/git/repositories/' + $repoName + '?api-version=' + $destVersion
$gitRepoUrl
if($destCtx.isOnline) {
    $repo = Invoke-RestMethod -Headers @{Authorization="Basic $($destCtx.base64AuthInfo)"} -Uri $gitRepoUrl
}
else {
    $repo = Invoke-RestMethod -Uri $gitRepoUrl -UseDefaultCredentials
}

$buildCreateUrl = $destCtx.projBaseUrl + '/build/definitions?&api-version=' + $destCtx.apiVersion
$newBuildDefName = $buildDefName # + '-' + $area

$buildDef.path = $buildPath
$buildDef.project.id = $destProjObj.id
$buildDef.project.name = $destProjObj.name
$buildDef.name = $newBuildDefName
$buildDef.repository.name = $repo.name
$buildDef.repository.id = $repo.id
$buildDef.repository.url = $repo.url
$buildDef.queue.id = 104 # TODO: use parameter
$buildDef.queue.name = 'ubuntu-18.04' # TODO: use parameter
$buildDef.queue.pool.id = 104
$buildDef.queue.pool.name = 'ubuntu-18.04'
$buildDef.variableGroups.Clear()
$buildDef.variableGroups += $varGroup



$data = $buildDef | ConvertTo-Json -Depth 100

if($destCtx.isOnline) {
    $response = Invoke-RestMethod -Headers @{Authorization="Basic $($destCtx.base64AuthInfo)"} -Uri $buildCreateUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $response = Invoke-RestMethod -Uri $buildCreateUrl -Method Post -Body $data -ContentType $contentType -UseDefaultCredentials
}

return $response

}
Function Get-AllGroups
{
    [CmdletBinding()]
param(
    [Parameter()][string]$projectName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'

$graphCtx = Get-AzureDevOpsContext -protocol https -coreServer vssps.dev.azure.com -org $context.org -project $context.project -apiVersion $context.apiVersion `
    -pat $context.pat -isOnline

$useDescriptor = ![string]::IsNullOrEmpty($projectName)
if($useDescriptor) {
    $descriptor = Get-ProjectDescriptor -projectName $projectName -context $context
}
$headers = @{ Authorization = "Basic $($context.base64AuthInfo)" }
$ctHeader = 'X-MS-ContinuationToken'
$result = @{
    count = 0
    value = @()
}
$ct = $null
do {
    if($useDescriptor) {
        $groupsUrl = $graphCtx.orgBaseUrl + '/graph/groups?scopeDescriptor=' + $descriptor.value + '&continuationToken=' + $ct + '&api-version=' + $v
    }
    else {
        $groupsUrl = $graphCtx.orgBaseUrl + '/graph/groups?continuationToken=' + $ct + '&api-version=' + $v
    }
    Write-Output $groupsUrl
    $r = Invoke-WebRequest -Headers $headers -Uri $groupsUrl
    $obj = $r.Content | ConvertFrom-Json 
    $result.count += $obj.count
    $result.value += $obj.value
    $ct = $r.Headers[$ctHeader]
} while($null -ne $ct)
    
return $result

}
Function Get-AllUsers
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'

$graphCtx = Get-AzureDevOpsContext -protocol https -coreServer vssps.dev.azure.com -org $context.org -project $context.project -apiVersion $context.apiVersion `
    -pat $context.pat -isOnline

$headers = @{ Authorization = "Basic $($context.base64AuthInfo)" }
$ctHeader = 'X-MS-ContinuationToken'
$result = @{
    count = 0
    value = @()
}
$ct = $null
do {
    $usersUrl = $graphCtx.orgBaseUrl + '/graph/users?continuationToken=' + $ct + '&api-version=' + $v
    Write-Output $usersUrl
    $r = Invoke-WebRequest -Headers $headers -Uri $usersUrl -UseBasicParsing
    $obj = $r.Content | ConvertFrom-Json 
    $result.count += $obj.count
    $result.value += $obj.value
    $ct = $r.Headers[$ctHeader]
} while($null -ne $ct)
    
return $result

}
# . .\AzureDevOpsContext.ps1

Function Get-AzureDevOpsContext {
    [CmdletBinding()]
    param(
      [ValidateNotNullOrEmpty()]
      [Parameter(Mandatory = $true)][string]$protocol,
      [Parameter(Mandatory = $true)][string]$coreServer,
      [Parameter(Mandatory = $true)][string]$org,
      [Parameter(Mandatory = $true)][string]$project,
      [Parameter(Mandatory = $true)][string]$apiVersion,
      [switch]$isOnline,
      [Parameter()][string]$pat
    )
    
  
    $orgBaseUrl = $protocol + '://' + $coreServer + '/' + $org + '/_apis'
    $orgUrl = $protocol + '://' + $coreServer + '/' + $org 
    $projectBaseUrl = $protocol + '://' + $coreServer + '/' + $org + '/' + $project + '/_apis'
    $projectUrl = $protocol + '://' + $coreServer + '/' + $org + '/' + $project
    
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($org):$pat"))
  
    # $r = [AzureDevOpsContext]::new()
    $r = New-Object AzureDevOpsContext

    $r.orgBaseUrl = $orgBaseUrl
    $r.orgUrl = $orgUrl
    $r.projectBaseUrl = $projectBaseUrl
    $r.projectUrl = $projectUrl
    $r.base64AuthInfo = $base64AuthInfo
    $r.protocol = $protocol
    $r.coreServer = $coreServer
    $r.org = $org
    $r.project = $project
    $r.apiVersion = $apiVersion
    $r.isOnline = $isOnline
    $r.pat = $pat
  
    return $r
  }
  
# . .\AzureDevOpsContext.ps1

Function Get-Build
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][int]$buildId,
    [Parameter()][string]$propertyFilters, # <empty>, all, <specific property>
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$buildDefUrl = $context.projectBaseUrl + '/build/builds/' + $buildId + '?propertyFilters=' + $propertyFilters + '&api-version=' + $context.apiVersion
Write-Host $buildDefUrl

if($context.isOnline) {
    $buildDef = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $buildDefUrl -Method Get
}
else {
    $buildDef = Invoke-RestMethod -Uri $buildDefUrl -UseDefaultCredentials -Method Post
}

return $buildDef

}
# . .\AzureDevOpsContext.ps1

Function Get-BuildDef
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][int]$buildDefId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$buildDefUrl = $context.projectBaseUrl + '/build/definitions/' + $buildDefId + '?api-version=' + $context.apiVersion
Write-Host $buildDefUrl

if($context.isOnline) {
    $buildDef = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $buildDefUrl -Method Get
}
else {
    $buildDef = Invoke-RestMethod -Uri $buildDefUrl -UseDefaultCredentials -Method Get
}

return $buildDef

}
# . .\AzureDevOpsContext.ps1

Function Get-BuildDefByName
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$buildDefName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$buildDefUrl = $context.projectBaseUrl + '/build/definitions?name=' + $buildDefName + '&api-version=' + $context.apiVersion
Write-Host $buildDefUrl

if($context.isOnline) {
    $buildDefs = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $buildDefUrl -Method Get
}
else {
    $buildDefs = Invoke-RestMethod -Uri $buildDefUrl -UseDefaultCredentials -Method Post
}

if($null -ne $buildDefs.value -and $buildDefs.value.length -gt 0) {
    return $buildDefs.value[0]
}
return $null

}
# . .\AzureDevOpsContext.ps1

Function Get-BuildDefProperties
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][int]$buildDefId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'
$buildDefPropsUrl = $context.projectBaseUrl + '/build/definitions/' + $buildDefId + '/properties?api-version=' + $v
Write-Host $buildDefUrl

if($context.isOnline) {
    $buildDefProps = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $buildDefPropsUrl -Method Get
}
else {
    $buildDefProps = Invoke-RestMethod -Uri $buildDefPropsUrl -UseDefaultCredentials -Method Post
}

return $buildDefProps

}
# . .\AzureDevOpsContext.ps1

Function Get-BuildDefs
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$ctHeader = 'X-MS-ContinuationToken'
$result = @{
    count = 0
    value = @()
}

$ct = $null
do {

$buildDefUrl = $context.projectBaseUrl + '/build/definitions?queryOrder=definitionNameAscending&continuationToken=' + $ct + '&api-version=' + $context.apiVersion
Write-Host $buildDefUrl

if($context.isOnline) {
    $r = Invoke-WebRequest -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $buildDefUrl -Method Get
}
else {
    $r = Invoke-WebRequest -Uri $buildDefUrl -UseDefaultCredentials -Method Get
}
$r
$obj = $r.Content | ConvertFrom-Json
$result.count += $obj.count
$result.value += $obj.value
$ct = $r.Headers[$ctHeader]

} while($null -ne $ct)

return $result

}
Function Get-DescriptorFromGroupDescriptor()
{
    Param(
        [Parameter(Mandatory = $true)][string]$groupDescriptor
    )

    $b64 = $groupDescriptor.Split('.')[1]
    $rem = [math]::ieeeremainder( $b64.Length, 4 ) 
    
    $str = ""
    $ln1 = 0
    $descriptor = ""

    if($rem -ne 0)
    {
        $ln1 = (4 - [math]::Abs($rem))
        if ($ln1 -gt 2)
        {
            $ln1 = 2
        }
        $str = ("=" * $ln1)
        $b64 +=  $str
    }
    try {
        Write-Host $b64
        $descriptor = ([System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($b64))).Trim()
    }
    catch {
          $ErrorMessage = $_.Exception.Message
          $FailedItem = $_.Exception.ItemName
          Write-Host "Security Error : " + $ErrorMessage + " Item : " + $FailedItem
    }
    return $descriptor
}
# . .\AzureDevOpsContext.ps1

Function Get-Feed
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$feedId,
    [Parameter()][switch]$orgLevel,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'
if($orgLevel) {
    $feedUrl = $context.orgBaseUrl + '/packaging/feeds/' + $feedId + '?api-version=' + $v
}
else {
    $feedUrl = $context.projectBaseUrl + '/packaging/feeds/' + $feedId + '?api-version=' + $v
}
Write-Host $feedUrl

if($context.isOnline) {
    $feed = Invoke-WebRequest -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $feedUrl -Method Get
}
else {
    $feed = Invoke-WebRequest -Uri $feedUrl -UseDefaultCredentials -Method Get
}
return $feed.Content | ConvertFrom-Json

}
# . .\AzureDevOpsContext.ps1

Function Get-FeedPackageByName
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$feedId,
    [Parameter(Mandatory=$true)][string]$packageName,
    [Parameter(Mandatory=$true)][string]$protocolType,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'

$packageUrl = "$($context.projectBaseUrl)/packaging/feeds/$feedId/packages?protocolType=$protocolType&packageNameQuery=$packageName&api-version=$v"
Write-Host $packageUrl

if($context.isOnline) {
    $result = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $packageUrl -Method Get
}
else {
    $result = Invoke-RestMethod -Uri $packageUrl -UseDefaultCredentials -Method Get
}

return $result

}
# . .\AzureDevOpsContext.ps1

Function Get-Feeds
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter()][switch]$orgLevel,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'
if($orgLevel) {
    $feedsUrl = $context.orgBaseUrl + '/packaging/feeds?api-version=' + $v
}
else {
    $feedsUrl = $context.projectBaseUrl + '/packaging/feeds?api-version=' + $v
}
Write-Host $feedsUrl

if($context.isOnline) {
    $feeds = Invoke-WebRequest -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $feedsUrl -Method Get
}
else {
    $feeds = Invoke-WebRequest -Uri $feedsUrl -UseDefaultCredentials -Method Get
}
return $feeds.Content | ConvertFrom-Json

}
# . .\AzureDevOpsContext.ps1

Function Get-FeedViews
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$feedId,
    [Parameter()][switch]$orgLevel,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'
if($orgLevel) {
    $feedViewsUrl = $context.orgBaseUrl + '/packaging/feeds/' + $feedId + '?api-version=' + $v
}
else {
    $feedViewsUrl = $context.projectBaseUrl + '/packaging/feeds/' + $feedId + '?api-version=' + $v
}
Write-Host $feedViewsUrl

if($context.isOnline) {
    $feedViews = Invoke-WebRequest -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $feedViewsUrl -Method Get
}
else {
    $feedViews = Invoke-WebRequest -Uri $feedViewsUrl -UseDefaultCredentials -Method Get
}
return $feedViews

}
# . .\AzureDevOpsContext.ps1

Function Get-Field
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$fieldNameOrRefName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

# GET https://dev.azure.com/{organization}/{project}/_apis/wit/fields/{fieldNameOrRefName}?api-version=6.0

$fieldUrl = $context.projectBaseUrl + '/wit/fields/' + $fieldNameOrRefName + '?api-version=' + $context.apiVersion
$fieldUrl

if($context.isOnline) {
    $field = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $fieldUrl -Method Get
}
else {
    $field = Invoke-RestMethod -Uri $fieldUrl -UseDefaultCredentials -Method Get
}

return $field

}
# . .\AzureDevOpsContext.ps1

Function Get-Fields
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

# GET https://dev.azure.com/{organization}/{project}/_apis/wit/fields?api-version=6.0

$fieldsUrl = $context.projectBaseUrl + '/wit/fields?api-version=' + $context.apiVersion
$fieldsUrl

if($context.isOnline) {
    $fields = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $fieldsUrl -Method Get
}
else {
    $fields = Invoke-RestMethod -Uri $fieldsUrl -UseDefaultCredentials -Method Get
}

return $fields

}
# . .\AzureDevOpsContext.ps1

Function Get-GitRepo
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$repoName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$gitRepoUrl = $context.projectBaseUrl + '/git/repositories/' + $repoName + '?api-version=' + $context.apiVersion
Write-Host $gitRepoUrl
if($context.isOnline) {
    $repo = Invoke-WebRequest -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $gitRepoUrl -Method Get -UseBasicParsing
}
else {
    $repo = Invoke-WebRequest -Uri $gitRepoUrl -UseDefaultCredentials -Method Get -UseBasicParsing
}
return $repo.Content | ConvertFrom-Json

}
# . .\AzureDevOpsContext.ps1

Function Get-GitRepos
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$gitReposUrl = $context.projectBaseUrl + '/git/repositories/?api-version=' + $context.apiVersion
Write-Host $gitReposUrl
if($context.isOnline) {
    $repo = Invoke-WebRequest -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $gitReposUrl -Method Get -UseBasicParsing
}
else {
    $repo = Invoke-WebRequest -Uri $gitReposUrl -UseDefaultCredentials -Method Get -UseBasicParsing
}
return $repo.Content | ConvertFrom-Json

}
# . .\AzureDevOpsContext.ps1
# . .\Get-AzureDevOpsContext.ps1
# . .\Get-Groups.ps1

Function Get-Group
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$projectName,
    [Parameter(Mandatory=$true)][string]$groupName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$groups = Get-Groups -projectName $projectName -context $context

$group = $groups.value | Where-Object { $_.principalName -eq "[$projectName]\$groupName" }
return $group

}
# . .\AzureDevOpsContext.ps1

Function Get-GroupAvatar
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$projectName,
    [Parameter(Mandatory=$true)][string]$groupName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'

$graphCtx = Get-AzureDevOpsContext -protocol https -coreServer vssps.dev.azure.com -org $context.org -project $context.project -apiVersion $context.apiVersion `
    -pat $context.pat -isOnline
$v = $context.apiVersion + '-preview.1'
$group = Get-Group -projectName $projectName -groupName $groupName -context $context

$avatarUrl = $graphCtx.orgBaseUrl + '/graph/Subjects/' + $group.descriptor + '/avatars?api-version=' + $v
Write-Host $avatarUrl

if($context.isOnline) {
    $avatar = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $avatarUrl
}
else {
    $avatar = Invoke-RestMethod -Uri $avatarUrl -UseDefaultCredentials
}

return $avatar

}
# . .\AzureDevOpsContext.ps1

Function Get-GroupAzDevOpsCli
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$projectName,
    [Parameter(Mandatory=$true)][string]$groupName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$group = az devops security group list `
    --organization "$($context.orgUrl)" `
    --project "$projectName" `
    --query "@.graphGroups[?@.principalName == '[$projectName]\$groupName'] | [0]"

return $group | ConvertFrom-Json

}
Function Get-GroupEntitlements
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)


$v = $context.apiVersion + '-preview.1'

$ctx = Get-AzureDevOpsContext -protocol https -coreServer vsaex.dev.azure.com -org $context.org -project $context.project -apiVersion $context.apiVersion `
    -pat $context.pat -isOnline

$groupEntitlementsUrl = $ctx.orgBaseUrl + '/groupentitlements?api-version=' + $v
Write-Output $groupEntitlementsUrl

if($context.isOnline) {
    $groupEntitlements = Invoke-RestMethod -Headers @{Authorization="Basic $($ctx.base64AuthInfo)"} -Uri $groupEntitlementsUrl
}
else {
    $groupEntitlements = Invoke-RestMethod -Uri $groupEntitlementsUrl -UseDefaultCredentials
}

return $groupEntitlements

}
# . .\AzureDevOpsContext.ps1
# . .\Get-Group.ps1

Function Get-GroupMembership
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$projectName,
    [Parameter(Mandatory=$true)][string]$groupName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$group = Get-Group -projectName $projectName -groupName $groupName -context $context
if($null -eq $group) {
    Write-Host "Group $groupName cannot be found in project $projectName."
    return $null
}

$members = az devops security group membership list `
    --organization "$($context.orgUrl)" `
    --id $group.descriptor

return $members # | ConvertFrom-Json

}
# . .\AzureDevOpsContext.ps1

Function Get-GroupPermissionAzDevOpsCli
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$groupName,
    # for list of namespaces, use: az devops security permission namespace list --query "[].name"
    # for both ids and names, use: az devops security permission namespace list --query "[].{ namespaceId: namespaceId, name: name}"
    [Parameter()][string]$namespaceName,
    [Parameter()][string]$namespaceId,
    # Security token for the namespace, see this link for token guidance:
    # https://docs.microsoft.com/en-us/azure/devops/cli/security_tokens?view=azure-devops
    [Parameter(Mandatory=$true)][string]$securityToken, 
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$currentLocation = Get-Location

$org = $context.org
$projName = $context.project

Set-Location $env:USERPROFILE

$subject = az devops security group list `
    --org "https://dev.azure.com/$org/" `
    --scope project `
    --project "$projName" `
    --subject-types vssgp `
    --query "graphGroups[?@.principalName == '[$projName]\$groupName'].descriptor | [0]"
Write-Host "subject: $subject"
 
if([String]::IsNullOrEmpty($namespaceId)) {
    $namespaceId = az devops security permission namespace list `
        --org "https://dev.azure.com/$org/" `
        --query "[?@.name == '$namespaceName'].namespaceId | [0]"
}
Write-Host "namespaceId: $namespaceId"

az devops security permission show `
    --id $namespaceId `
    --subject $subject `
    --token $securityToken `
    --org https://dev.azure.com/$org/

Set-Location $currentLocation

}


# . .\AzureDevOpsContext.ps1
# . .\Get-AzureDevOpsContext.ps1
# . .\Get-ProjectDescriptor.ps1

Function Get-Groups
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$projectName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)


$v = $context.apiVersion + '-preview.1'

$graphCtx = Get-AzureDevOpsContext -protocol https -coreServer vssps.dev.azure.com -org $context.org -project $context.project -apiVersion $context.apiVersion `
    -pat $context.pat -isOnline

$descriptor = Get-ProjectDescriptor -projectName $projectName -context $context
$groupsUrl = $graphCtx.orgBaseUrl + '/graph/groups?scopeDescriptor=' + $descriptor.value + '&api-version=' + $v

Write-Host $groupsUrl
if($context.isOnline) {
    $groups = Invoke-RestMethod -Headers @{Authorization="Basic $($graphCtx.base64AuthInfo)"} -Uri $groupsUrl -Method Get
}
else {
    $groups = Invoke-RestMethod -Uri $groupsUrl -Method Get -UseDefaultCredentials
}

return $groups

}
# . .\AzureDevOpsContext.ps1

Function Get-IdentityBySubjectDescriptor
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$subjectDescriptor,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'
$graphCtx = Get-AzureDevOpsContext -protocol https -coreServer vssps.dev.azure.com -org $context.org -project $context.project -apiVersion $context.apiVersion `
    -pat $context.pat -isOnline

$descriptorUrl = $graphCtx.orgBaseUrl + '/identities?subjectDescriptors=' + $subjectDescriptor + '&api-version=' + $v
Write-Host $descriptorUrl

if($context.isOnline) {
    $descriptorObj = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $descriptorUrl -Method Get
}
else {
    $descriptorObj = Invoke-RestMethod -Uri $descriptorUrl -UseDefaultCredentials -Method Post
}

if($null -ne $descriptorObj.value -and $descriptorObj.value.length -gt 0) {
    return $descriptorObj.value[0]
}

return $null

}
# NOT WORKING WITH THE CONTEXT
# . .\AzureDevOpsContext.ps1

Function Get-MemberOrgs
{
param(
    [ValidateNotNullOrEmpty()]
    # use the following link to get own profile info: https://app.vssps.visualstudio.com/_apis/profile/profiles/me?api-version=5.1
    [Parameter(Mandatory=$true)][string]$memberId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$accountsUrl = 'https://app.vssps.visualstudio.com/_apis/accounts?memberId=' + $memberId + '&api-version=' + $context.apiVersion
Write-Host $accountsUrl

if($context.isOnline) {
    $accounts = Invoke-WebRequest -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $accountsUrl -Method Get
}
else {
    $accounts = Invoke-WebRequest -Uri $accountsUrl -UseDefaultCredentials -Method Get
}
return $accounts

}
# . .\AzureDevOpsContext.ps1
# . .\Get-Projects.ps1
# . .\Get-GroupAzDevOpsCli.ps1
# . .\Get-GroupMembership.ps1

Function Get-OrgGroupMembership
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$groupName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$projects = Get-Projects -context $context
$groupsMembers = @()
$projects | ForEach-Object {
    $groupMembers = @{}
    $groupMembers.groupName = "[$($_.name)]\$groupName"
    $members = (Get-GroupMembership -projectName $_.name -groupName $groupName -context $context) | ConvertFrom-Json
    $mbs = @()
    $members.PSObject.Properties | ForEach-Object { $mbs += $_.Value }
    $groupMembers.members = $mbs

    $groupsMembers += $groupMembers
}

return $groupsMembers

}
# . .\AzureDevOpsContext.ps1

Function Get-PermissionsReport
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$reportId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + "-preview.1"
$permissionsReportUrl = $context.orgBaseUrl + "/permissionsreport/" + $reportId + "?api-version=" + $v
Write-Output $permissionsReportUrl

if($context.isOnline) {
    $report = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $permissionsReportUrl
}
else {
    $report = Invoke-RestMethod -Uri $permissionsReportUrl -UseDefaultCredentials
}

return $report

}
# . .\AzureDevOpsContext.ps1

Function Get-PermissionsReportDownload
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$reportId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + "-preview.1"
$permissionsReportUrl = $context.orgBaseUrl + "/permissionsreport/" + $reportId + "/download?api-version=" + $v
Write-Output $permissionsReportUrl

if($context.isOnline) {
    $report = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $permissionsReportUrl
}
else {
    $report = Invoke-RestMethod -Uri $permissionsReportUrl -UseDefaultCredentials
}

return $report

}
# . .\AzureDevOpsContext.ps1

Function Get-PermissionsReports
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + "-preview.1"
$permissionsReportUrl = $context.orgBaseUrl + "/permissionsreport?api-version=" + $v
Write-Output $permissionsReportUrl

if($context.isOnline) {
    $reports = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $permissionsReportUrl
}
else {
    $reports = Invoke-RestMethod -Uri $permissionsReportUrl -UseDefaultCredentials
}

return $reports

}
# . .\AzureDevOpsContext.ps1

Function Get-PipelineArtifact
{
    [CmdletBinding()]
param(
    [Parameter()][string]$pipelineId,
    [Parameter()][string]$pipelineName,
    [Parameter(Mandatory=$true)][string]$artifactName,
    [Parameter(Mandatory=$true)][string]$runId,
    [Parameter()][switch]$download,
    [Parameter()][string]$outputFilePath,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

if([string]::IsNullOrEmpty(($pipelineId))) {
    $pipeline = Get-BuildDefByName -buildDefName $pipelineName -context $context
    $pipelineId = $pipeline.id
}
$v = $context.apiVersion + '-preview.1'
$artifactUrl = $context.projectBaseUrl + '/pipelines/' + $pipelineId + '/runs/' + $runId + '/artifacts?artifactName=' + $artifactName + '&$expand=signedContent&api-version=' + $v
Write-Host $artifactUrl

if($context.isOnline) {
    $artifact = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $artifactUrl -Method Get
}
else {
    $artifact = Invoke-RestMethod -Uri $artifactUrl -UseDefaultCredentials -Method Get
}

if($download) {
    $downloadUrl = [System.Web.HttpUtility]::UrlDecode($artifact.signedContent.url) 
    Write-Host $downloadUrl
    if($context.isOnline) {
        $artifact = Invoke-WebRequest -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $downloadUrl -Method Get -OutFile $outputFilePath
    }
    else {
        $artifact = Invoke-WebRequest -Uri $downloadUrl -UseDefaultCredentials -Method Get -OutFile $outputFilePath
    }   
}

return $artifact

}
# . .\AzureDevOpsContext.ps1

Function Get-Pipelines
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$ctHeader = 'X-MS-ContinuationToken'
$result = @{
    count = 0
    value = @()
}

$ct = $null
do {

$pipelinesUrl = $context.projectBaseUrl + '/pipelines?continuationToken=' + $ct + '&api-version=' + $context.apiVersion
Write-Host $pipelinesUrl

if($context.isOnline) {
    $r = Invoke-WebRequest -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $pipelinesUrl -Method Get
}
else {
    $r = Invoke-WebRequest -Uri $pipelinesUrl -UseDefaultCredentials -Method Get
}
$r
$obj = $r.Content | ConvertFrom-Json
$result.count += $obj.count
$result.value += $obj.value
$ct = $r.Headers[$ctHeader]

} while($null -ne $ct)

return $result

}
# . .\AzureDevOpsContext.ps1

Function Get-PoolAgentByName
{
    [CmdletBinding()]
param(
    [Parameter()][string]$poolId,
    [Parameter()][string]$poolName,
    [Parameter()][string]$agentName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

if([string]::IsNullOrEmpty($poolId)) {
    $pool = Get-PoolByName -poolName $poolName -context $context
    $poolId = $pool.id
}
$v = $context.apiVersion + '-preview.1'

$agentsUrl = $context.orgBaseUrl + '/distributedtask/pools/' + $poolId + '/agents?agentName=' + $agentName + '&api-version=' + $v
Write-Host $agentsUrl

if($context.isOnline) {
    $agents = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $agentsUrl -Method Get
}
else {
    $agents = Invoke-RestMethod -Uri $agentsUrl -UseDefaultCredentials -Method Post
}

if($null -ne $agents.value -and $agents.value.length -gt 0) {
    return $agents.value[0]
}
return $null

}
# . .\AzureDevOpsContext.ps1

Function Get-PoolAgents
{
    [CmdletBinding()]
param(
    [Parameter()][string]$poolId,
    [Parameter()][string]$poolName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

if([string]::IsNullOrEmpty($poolId)) {
    $pool = Get-PoolByName -poolName $poolName -context $context
    $poolId = $pool.id
}
$v = $context.apiVersion + '-preview.1'

$agentsUrl = $context.orgBaseUrl + '/distributedtask/pools/' + $poolId + '/agents?api-version=' + $v
Write-Host $agentsUrl

if($context.isOnline) {
    $agents = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $agentsUrl -Method Get
}
else {
    $agents = Invoke-RestMethod -Uri $agentsUrl -UseDefaultCredentials -Method Post
}

return $agents

}
# . .\AzureDevOpsContext.ps1

Function Get-PoolByName
{
    [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$poolName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'

$poolUrl = $context.orgBaseUrl + '/distributedtask/pools?poolName=' + $poolName + '&api-version=' + $v
Write-Host $poolUrl

if($context.isOnline) {
    $pool = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $poolUrl -Method Get
}
else {
    $pool = Invoke-RestMethod -Uri $poolUrl -UseDefaultCredentials -Method Post
}

if($null -ne $pool.value -and $pool.value.length -gt 0) {
    return $pool.value[0]
}
return $null

}
# . .\AzureDevOpsContext.ps1

Function Get-PoolJobs
{
    [CmdletBinding()]
param(
    [Parameter()][string]$poolId,
    [Parameter()][string]$poolName,
    [ValidateSet("", "succeeded", "failed", "canceled")] # use "" for running jobs
    [string]$result,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

if([string]::IsNullOrEmpty($poolId)) {
    $pool = Get-PoolByName -poolName $poolName -context $context
    $poolId = $pool.id
}

$jobsUrl = $context.orgBaseUrl + '/distributedtask/pools/' + $poolId + '/jobrequests?api-version=' + $context.apiVersion
Write-Host $jobsUrl

if($context.isOnline) {
    $jobs = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $jobsUrl -Method Get
}
else {
    $jobs = Invoke-RestMethod -Uri $jobsUrl -UseDefaultCredentials -Method Post
}

if([string]::IsNullOrEmpty($result)) {
    $filteresJobs = $jobs.value | Where-Object { $_.PSobject.Properties.name -notcontains "result" }
}
else {
    $filteresJobs = $jobs.value.Where({ $_.result -eq $result })
}

return $filteresJobs

}
# . .\AzureDevOpsContext.ps1

Function Get-Processes
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$processesUrl = $context.orgBaseUrl + '/process/processes?api-version=' + $context.apiVersion

Write-Host $processesUrl
if($context.isOnline) {
    $processes = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $processesUrl -Method Get
}
else {
    $processes = Invoke-RestMethod -Uri $processesUrl -Method Get -UseDefaultCredentials
}

return $processes

}
# . .\AzureDevOpsContext.ps1

Function Get-ProcessWITField
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$processId,
    [Parameter(Mandatory=$true)][string]$witRefName,
    [Parameter(Mandatory=$true)][string]$fieldRefName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

# GET https://dev.azure.com/{organization}/_apis/work/processes/{processId}/workItemTypes/{witRefName}/fields/{fieldRefName}?api-version=6.1-preview.2
$v = $context.apiVersion + '-preview.2'
$fieldUrl = $context.orgBaseUrl + '/work/processes/' + $processId + '/workItemTypes/' + $witRefName + '/fields/' + $fieldRefName + '?api-version=' + $v
$fieldUrl

if($context.isOnline) {
    $field = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $fieldUrl -Method Get
}
else {
    $field = Invoke-RestMethod -Uri $fieldUrl -UseDefaultCredentials -Method Get
}

return $field

}
# . .\AzureDevOpsContext.ps1

Function Get-ProcessWITFields
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$processId,
    [Parameter(Mandatory=$true)][string]$witRefName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

# GET https://dev.azure.com/{organization}/_apis/work/processes/{processId}/workItemTypes/{witRefName}/fields?api-version=6.1-preview.2
$v = $context.apiVersion + '-preview.2'
$fieldsUrl = $context.orgBaseUrl + '/work/processes/' + $processId + '/workItemTypes/' + $witRefName + '/fields?api-version=' + $v
$fieldsUrl

if($context.isOnline) {
    $fields = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $fieldsUrl -Method Get
}
else {
    $fields = Invoke-RestMethod -Uri $fieldsUrl -UseDefaultCredentials -Method Get
}

return $fields

}
# . .\AzureDevOpsContext.ps1

Function Get-ProcessWITs
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$processId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

# GET https://dev.azure.com/{organization}/_apis/work/processes/{processId}/workitemtypes?api-version=6.1-preview.2
$v = $context.apiVersion + '-preview.2'
$witsUrl = $context.orgBaseUrl + '/work/processes/' + $processId + '/workItemTypes?api-version=' + $v
$witsUrl

if($context.isOnline) {
    $wits = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $witsUrl -Method Get
}
else {
    $wits = Invoke-RestMethod -Uri $witsUrl -UseDefaultCredentials -Method Get
}

return $wits

}
# . .\AzureDevOpsContext.ps1

Function Get-Project
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$projectName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$projectApiUrl = $context.orgBaseUrl + '/projects/' + $projectName + '?api-version=' + $context.apiVersion
Write-Host $projectApiUrl
if($context.isOnline) {
    $project = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $projectApiUrl -Method Get -UseBasicParsing
}
else {
    $project = Invoke-RestMethod -Uri $projectApiUrl -Method Get -UseDefaultCredentials -UseBasicParsing
}

return $project

}
# . .\AzureDevOpsContext.ps1
# . .\Get-Project.ps1

Function Get-ProjectDescriptor
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$projectName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$proj = Get-Project -projectName $projectName -context $context
$graphCtx = Get-AzureDevOpsContext -protocol https -coreServer vssps.dev.azure.com -org $context.org -project $context.project -apiVersion $context.apiVersion `
    -pat $context.pat -isOnline
$v = $context.apiVersion + '-preview.1'

$descriptorUrl = $graphCtx.orgBaseUrl + '/graph/descriptors/' + $proj.id + '?api-version=' + $v
Write-Host $projectApiUrl
if($context.isOnline) {
    $descriptor = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $descriptorUrl -Method Get
}
else {
    $descriptor = Invoke-RestMethod -Uri $descriptorUrl -Method Get -UseDefaultCredentials
}

return $descriptor

}
# . .\AzureDevOpsContext.ps1
<#
.SYNOPSIS
    This function returns the list of Azure DevOps projects in an organization.

.DESCRIPTION
    This function returns the list of Azure DevOps projects in an organization, beased on authentication context.
    It works for both Azure DevOps Services and Server.
    Requires ... permissions.

.PARAMETER context
    The parameter context is used to define the value of blah and also blah.

.EXAMPLE

Import-Module .\AzureDevOps.psm1

$org = '{org}'
$projName = 'xyz'
$pat = '***'

# create an Azure DevOps context for AuthN
# . .\Get-AzureDevOpsContext.ps1
$context = Get-AzureDevOpsContext -protocol https -coreServer dev.azure.com -org $org -project $projName -apiVersion 6.0 `
    -pat $pat -isOnline

# get the list of projects
$projects = Get-Projects -context $context

.NOTES
    Author: Dan Radu
    Last Edit: 2020-10-21
    Version 1.0 - initial release of AzureDevOps module

#>
Function Get-Projects
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$projectsApiUrl = $context.orgBaseUrl + '/projects/?api-version=' + $context.apiVersion
Write-Host $projectsApiUrl
if($context.isOnline) {
    $projects = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $projectsApiUrl -Method Get
}
else {
    $projects = Invoke-RestMethod -Uri $projectsApiUrl -Method Get -UseDefaultCredentials
}

return $projects.value

}
# . .\AzureDevOpsContext.ps1
# . .\Get-GitRepo.ps1

Function Get-PullRequest
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$repoName,
    [Parameter(Mandatory=$true)][int]$pullRequestId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$repo = Get-GitRepo -repoName $repoName -context $context

$pullRequestUrl = $context.projectBaseUrl + '/git/repositories/' + $repo.id +'/pullrequests/' + $pullRequestId + '?api-version=' + $context.apiVersion
$pullRequestUrl

if($context.isOnline) {
    $pullRequest = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $pullRequestUrl -Method Get
}
else {
    $pullRequest = Invoke-RestMethod -Uri $pullRequestUrl -UseDefaultCredentials -Method Get
}

return $pullRequest

}
# . .\AzureDevOpsContext.ps1

Function Get-QueueByName
{
    [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$queueName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'

$queuesUrl = $context.projectBaseUrl + '/distributedtask/queues?queueName=' + $queueName + '&api-version=' + $v
Write-Host $queuesUrl

if($context.isOnline) {
    $queues = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $queuesUrl -Method Get
}
else {
    $queues = Invoke-RestMethod -Uri $queuesUrl -UseDefaultCredentials -Method Post
}

if($null -ne $queues.value -and $queues.value.length -gt 0) {
    return $queues.value[0]
}
return $null

}
# . .\AzureDevOpsContext.ps1

Function Get-ReleaseDef
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$releaseDefId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$releaseDefUrl = $context.projectBaseUrl + '/release/definitions/' + $releaseDefId + '?api-version=' + $context.apiVersion
Write-Host $releaseDefUrl

if($context.isOnline) {
    $releaseDef = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $releaseDefUrl -Method Get
}
else {
    $releaseDef = Invoke-RestMethod -Uri $releaseDefUrl -UseDefaultCredentials -Method Get
}

return $releaseDef

}
# . .\AzureDevOpsContext.ps1

Function Get-ReleaseDefByName
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$releaseDefName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$releaseDefUrl = $context.projectBaseUrl + '/release/definitions?searchText=' + $releaseDefName + '&api-version=' + $context.apiVersion
Write-Host $releaseDefUrl

if($context.isOnline) {
    $releaseDefs = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $releaseDefUrl -Method Get
}
else {
    $releaseDefs = Invoke-RestMethod -Uri $releaseDefUrl -UseDefaultCredentials -Method Get
}

if($null -ne $releaseDefs.value -and $releaseDefs.value.length -gt 0) {
    return $releaseDefs.value[0]
}

return $null

}
# . .\AzureDevOpsContext.ps1

Function Get-ReleaseDefs
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$ctHeader = 'X-MS-ContinuationToken'
$result = @{
    count = 0
    value = @()
}

$ct = $null
do {

$releaseDefsUrl = $context.projectBaseUrl + '/release/definitions?queryOrder=nameAscending&continuationToken=' + $ct + '&api-version=' + $context.apiVersion
Write-Host $releaseDefsUrl

if($context.isOnline) {
    $r = Invoke-WebRequest -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $releaseDefsUrl -Method Get
}
else {
    $r = Invoke-WebRequest -Uri $releaseDefsUrl -UseDefaultCredentials -Method Get
}

$obj = $r.Content | ConvertFrom-Json 
$result.count += $obj.count
$result.value += $obj.value
$ct = $r.Headers[$ctHeader]

} while($null -ne $ct)

return $result

}
# . .\AzureDevOpsContext.ps1

Function Get-RepoPolicies
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$policiesUrl = $context.projectBaseUrl + '/policy/configurations?api-version=' + $context.apiVersion
Write-Host $policiesUrl
if($context.isOnline) {
    $policies = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $policiesUrl -Method Get
}
else {
    $policies = Invoke-RestMethod -Uri $policiesUrl -Method Get -UseDefaultCredentials
}

return $policies

}
# . .\AzureDevOpsContext.ps1

Function Get-RepoPolicyTypes
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$policyTypesUrl = $context.projectBaseUrl + '/policy/types?api-version=' + $context.apiVersion
Write-Host $policyTypesUrl
if($context.isOnline) {
    $policyTypes = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $policyTypesUrl -Method Get
}
else {
    $policyTypes = Invoke-RestMethod -Uri $policyTypesUrl -Method Get -UseDefaultCredentials
}

return $policyTypes

}
# . .\AzureDevOpsContext.ps1

Function Get-SecurityNamespace {
    [CmdletBinding()]
param(
    [Parameter()][string]$namespaceName,
    [Parameter()][string]$namespaceId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$securityNamespaces = Get-SecurityNamespaces -context $context

if(![string]::IsNullOrEmpty($namespaceName)) {
    $securityNamespace = $securityNamespaces.value | Where-Object { $_.name -eq $namespaceName }
    return $securityNamespace
}

if(![string]::IsNullOrEmpty($namespaceId)) {
    $securityNamespace = $securityNamespaces.value | Where-Object { $_.namespaceId -eq $namespaceId }
    return $securityNamespace
}

return $null 

}
# . .\AzureDevOpsContext.ps1

Function Get-SecurityNamespaces
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$secNamespacesUrl = $context.orgBaseUrl + '/securitynamespaces?api-version=' + $context.apiVersion
Write-Host $secNamespacesUrl

if($context.isOnline) {
    $securityNamespaces = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $secNamespacesUrl -Method Get
}
else {
    $securityNamespaces = Invoke-RestMethod -Uri $secNamespacesUrl -UseDefaultCredentials -Method Post
}

return $securityNamespaces

}
# . .\AzureDevOpsContext.ps1

Function Get-ServiceEndpointByName
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$endpointName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.4'
$endpointUrl = $context.projectBaseUrl + '/serviceendpoint/endpoints?endpointNames=' + $endpointName + '&api-version=' + $v
Write-Host $endpointUrl

if($context.isOnline) {
    $endpoints = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $endpointUrl -Method Get
}
else {
    $endpoints = Invoke-RestMethod -Uri $endpointUrl -UseDefaultCredentials -Method Get
}

if($null -ne $endpoints.value -and $endpoints.value.length -gt 0) {
    return $endpoints.value[0]
}

return $null

}
# . .\AzureDevOpsContext.ps1
# . .\Get-TaskGroups.ps1

Function Get-TaskGroup
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$taskGroupId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'

$taskGroupUrl = $context.projectBaseUrl + '/distributedtask/taskgroups' + $taskGroupId + '?api-version=' + $v
Write-Host $taskGroupUrl

if($context.isOnline) {
    $taskGroup = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $taskGroupUrl -Method Get
}
else {
    $taskGroup = Invoke-RestMethod -Uri $taskGroupUrl -UseDefaultCredentials -Method Get
}

return $taskGroup

}
# . .\AzureDevOpsContext.ps1
# . .\Get-TaskGroups.ps1

Function Get-TaskGroupByName
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$taskGroupName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$taskGroups = Get-TaskGroups -context $context 
$taskGroup = $taskGroups.value | Where-Object { $_.name -eq $taskGroupName }
return $taskGroup

}
# . .\AzureDevOpsContext.ps1

Function Get-TaskGroups
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'

$taskGroupsUrl = $context.projectBaseUrl + '/distributedtask/taskgroups?api-version=' + $v
Write-Host $taskGroupsUrl

if($context.isOnline) {
    $taskGroups = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $taskGroupsUrl -Method Get
}
else {
    $taskGroups = Invoke-RestMethod -Uri $taskGroupsUrl -UseDefaultCredentials -Method Get
}

return $taskGroups

}
# . .\AzureDevOpsContext.ps1

Function Get-UniversalPackage
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$packageName,
    [Parameter(Mandatory=$true)][string]$feedId, # name or ID
    [Parameter(Mandatory=$true)][string]$outputPath,
    [Parameter(Mandatory=$true)][string]$packageVersion, # use semantic version, i.e. 1.0.0
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$currentLocation = Get-Location

Set-Location $env:USERPROFILE

az artifacts universal download --feed $feedId `
    --name $packageName `
    --path $outputPath `
    --version $packageVersion `
    --detect true `
    --organization $context.orgUrl

Set-Location $currentLocation

}


# . .\AzureDevOpsContext.ps1
# . .\Get-AzureDevOpsContext.ps1
# . .\Get-Users.ps1

Function Get-User
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$userName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$users = Get-Users -context $context

$user = $users.value | Where-Object { $_.principalName -eq "$userName" }
return $user

}
Function Get-UserEntitlements
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)


$v = $context.apiVersion + '-preview.3'

$ctx = Get-AzureDevOpsContext -protocol https -coreServer vsaex.dev.azure.com -org $context.org -project $context.project -apiVersion $context.apiVersion `
    -pat $context.pat -isOnline

$userEntitlementsUrl = $ctx.orgBaseUrl + '/userentitlements?api-version=' + $v
Write-Output $userEntitlementsUrl

if($context.isOnline) {
    $userEntitlements = Invoke-RestMethod -Headers @{Authorization="Basic $($ctx.base64AuthInfo)"} -Uri $userEntitlementsUrl
}
else {
    $userEntitlements = Invoke-RestMethod -Uri $userEntitlementsUrl -UseDefaultCredentials
}

return $userEntitlements

}

Function Get-UserPermissionAzDevOpsCli
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$userName, # Email or ID
    # for list of namespaces, use: az devops security permission namespace list --query "[].name"
    # for both ids and names, use: az devops security permission namespace list --query "[].{ namespaceId: namespaceId, name: name}"
    [Parameter()][string]$namespaceName,
    [Parameter()][string]$namespaceId,
    # Security token for the namespace, see this link for token guidance:
    # https://docs.microsoft.com/en-us/azure/devops/cli/security_tokens?view=azure-devops
    [Parameter(Mandatory=$true)][string]$securityToken, 
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$currentLocation = Get-Location

$org = $context.org

Set-Location $env:USERPROFILE

$subject = az devops user show `
    --org "https://dev.azure.com/$org/" `
    --user $userName `
    --query "user.descriptor"
Write-Host "subject: $subject"
 
if([String]::IsNullOrEmpty($namespaceId)) {
    $namespaceId = az devops security permission namespace list `
        --org "https://dev.azure.com/$org/" `
        --query "[?@.name == '$namespaceName'].namespaceId | [0]"
}
Write-Host "namespaceId: $namespaceId"

az devops security permission show `
    --id $namespaceId `
    --subject $subject `
    --token $securityToken `
    --org https://dev.azure.com/$org/

Set-Location $currentLocation

}


# . .\AzureDevOpsContext.ps1
# . .\Get-AzureDevOpsContext.ps1

Function Get-Users
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'

$graphCtx = Get-AzureDevOpsContext -protocol https -coreServer vssps.dev.azure.com -org $context.org -project $context.project -apiVersion $context.apiVersion `
    -pat $context.pat -isOnline

$usersUrl = $graphCtx.orgBaseUrl + '/graph/users?subjectTypes=msa,aad,svc&api-version=' + $v

Write-Host $usersUrl
if($context.isOnline) {
    $users = Invoke-RestMethod -Headers @{Authorization="Basic $($graphCtx.base64AuthInfo)"} -Uri $usersUrl -Method Get
}
else {
    $users = Invoke-RestMethod -Uri $usersUrl -Method Get -UseDefaultCredentials
}

return $users

}
# . .\AzureDevOpsContext.ps1

Function Get-VarGroup
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][int]$groupId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$varGroupUrl = $context.projectBaseUrl + '/distributedtask/variablegroups/' + $groupId + '?api-version=' + $context.apiVersion
$varGroupUrl


if($context.isOnline) {
    $varGroup = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $varGroupUrl -Method Get
}
else {
    $varGroup = Invoke-RestMethod -Uri $varGroupsUrl -UseDefaultCredentials -Method Get
}

return $varGroup
<#
# $varGroup.variables | Get-Member -MemberType 'NoteProperty' | Select-Object -ExpandProperty $_.Name # | ConvertTo-Json
$props = Get-Member -InputObject $varGroup.variables -MemberType NoteProperty

foreach($prop in $props) {
    $propValue = $varGroup.variables | Select-Object -ExpandProperty $prop.Name
    "$($prop.Name),""$($propValue.value)"""
}
#>

}
# . .\AzureDevOpsContext.ps1

Function Get-VarGroupByName
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$varGroupName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$varGroups = Get-VarGroups -context $context
if($null -ne $varGroups.value -and $varGroups.value.length -gt 0) {
    $varGroup = $varGroups.value | Where-Object { $_.name -eq $varGroupName }
    return $varGroup
}
return $null

}
# . .\AzureDevOpsContext.ps1

Function Get-VarGroups
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.2'
$varGroupsUrl = $context.projectBaseUrl + '/distributedtask/variablegroups?api-version=' + $v
$varGroupsUrl


if($context.isOnline) {
    $varGroups = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $varGroupsUrl -Method Get
}
else {
    $varGroups = Invoke-RestMethod -Uri $varGroupsUrl -UseDefaultCredentials -Method Get
}

return $varGroups

}
# . .\AzureDevOpsContext.ps1
# . .\Get-VarGroup.ps1

Function Get-VarGroupVariablesAsCsv
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][int]$groupId,
    [Parameter(Mandatory=$true)][string]$outputCsvFilePath,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$varGroup = Get-VarGroup -groupId $groupId -context $context
$props = Get-Member -InputObject $varGroup.variables -MemberType NoteProperty
$s = ''
foreach($prop in $props) {
    $propValue = $varGroup.variables | Select-Object -ExpandProperty $prop.Name
    $s += "$($prop.Name),""$($propValue.value)""
"
}
$s > $outputCsvFilePath
return $s

}
# . .\AzureDevOpsContext.ps1

Function Get-VarGroupVars
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter()][string]$varGroupId,
    [Parameter()][string]$varGroupName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

if([string]::IsNullOrEmpty($varGroupId)) {
    $varGroup = Get-VarGroupByName -varGroupName $varGroupName -context $context
    $varGroupId = $varGroup.id
} 
else {
    $varGroup = Get-VarGroup -groupId $varGroupId -context $context
}

$vars = @{}
$varGroup.variables.PSObject.Properties | ForEach-Object { 
    $key = $_.Name
    $value = $_.Value.value
    $vars[$key] = $value;
 }
 
 return $vars

}
# . .\AzureDevOpsContext.ps1

Function Get-WIT
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$processId,
    [Parameter(Mandatory=$true)][string]$witRefName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)


$witUrl = $context.orgBaseUrl + '/work/processes/' + $processId + '/workitemtypes/' + $witRefName + '?api-version=' + $context.apiVersion
Write-Host $witUrl

if($context.isOnline) {
    $wit = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $witUrl -Method Get
}
else {
    $wit = Invoke-RestMethod -Uri $witUrl -UseDefaultCredentials -Method Get
}

return $wit

}
# . .\AzureDevOpsContext.ps1

Function Get-WorkItems
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$ids,
    [Parameter()][datetime]$asOfDate,
    [Parameter()][string]$expand,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$wiUrl = $context.projectBaseUrl + "/wit/workitems?ids=$ids"
$queryString = ''
$query = @{}
if($asOfDate) { $query.asOf = $asOfDate }
if($expand) { $query.expand = $expand  }
$query.Keys | ForEach-Object {
    $queryString += $p + "&$_=$($query[$_])"
}
$wiUrl += '&api-version=' + $context.apiVersion
Write-Host $wiUrl

if($context.isOnline) {
    $result = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $wiUrl -Method Get
}
else {
    $result = Invoke-RestMethod -Uri $wiUrl -UseDefaultCredentials -Method Post
}

return $result

}
# . .\AzureDevOpsContext.ps1

Function Import-BuildDef
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$jsonDefFilePath,
    [Parameter(Mandatory=$true)][string]$buildDefName,
    [Parameter(Mandatory=$true)][string]$projectId,
    [Parameter(Mandatory=$true)][string]$projectName,
    [Parameter(Mandatory=$true)][string]$repoId,
    [Parameter(Mandatory=$true)][string]$repoName,
    [Parameter()][string]$taskGroupId,
    [ValidateSet("", "project", "projectCollection")]
    [Parameter()][string]$jobAuthorizationScope,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$json = Get-Content -Path $jsonDefFilePath -Raw
$buildDef = ConvertFrom-Json -InputObject $json
$buildDef.name = $buildDefName
$buildDef.project.id = $projectId
$buildDef.project.name = $projectName
$buildDef.repository.id = $repoId
$buildDef.repository.name = $repoName
$buildDef.queue.id = $null
if(![string]::IsNullOrEmpty($taskGroupId)) {
    $buildDef.process.phases[0].steps[0].task.id = $taskGroupId
}
if(![string]::IsNullOrEmpty($jobAuthorizationScope)) {
    $buildDef.jobAuthorizationScope = $jobAuthorizationScope
}

$contentType = 'application/json'

$buildDefUrl = $context.projectBaseUrl + '/build/definitions?api-version=' + $context.apiVersion
Write-Host $buildDefUrl

$data = ConvertTo-Json -InputObject $buildDef -Depth 100

if($context.isOnline) {
    $newBuildDef = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $buildDefUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $newBuildDef = Invoke-RestMethod -Uri $buildDefUrl -UseDefaultCredentials -Method Post -Body $data -ContentType $contentType
}

return $newBuildDef

}
# . .\AzureDevOpsContext.ps1

# It works only with collections migrated using the Azure DevOps migrator (high-fidelity)
Function Import-ProcessTemplate
{
param(
    [Parameter(Mandatory=$true)][string]$zipFilePath,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)
$contentType = 'application/octet-stream'

$v = $context.apiVersion + '-preview.1';
$content = [System.IO.File]::ReadAllBytes($zipFilePath)

$importProcessUrl = $context.orgBaseUrl + '/work/processadmin/processes/import?api-version=' + $v
Write-Host $importProcessUrl

if($context.isOnline) {
    $importResult = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $importProcessUrl -Method Post -Body $content -ContentType $contentType
}
else {
    $importResult = Invoke-RestMethod -Uri $importProcessUrl -UseDefaultCredentials -Method Post -Body $content -ContentType $contentType
}

return $importResult;
}
# . .\AzureDevOpsContext.ps1
# . .\Get-Project.ps1
# . .\Get-GitRepo.ps1
# . .\Get-User.ps1
# . .\Get-Group.ps1

Function Import-PullRequest
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$jsonDefFilePath,
    [Parameter(Mandatory=$true)][string]$repoName,
    [Parameter(Mandatory=$true)][string]$title,
    [Parameter(Mandatory=$true)][string]$description,
    [Parameter(Mandatory=$true)][string]$sourceBranchName,
    [Parameter(Mandatory=$true)][string]$targetBranchName,
    [Parameter(Mandatory=$true)][string]$reviewerId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'

$json = Get-Content -Path $jsonDefFilePath -Raw
$pullRequest = ConvertFrom-Json -InputObject $json

$project = Get-Project -projectName $context.project -context $context
$repo = Get-GitRepo -repoName $repoName -context $context
$pullRequest.repository.id = $repo.id
$pullRequest.repository.name = $repoName
$pullRequest.repository.project.id = $project.id
$pullRequest.repository.project.name = $project.name
$pullRequest.title = $title
$pullRequest.description = $description
$pullRequest.sourceRefName = "refs/heads/$sourceBranchName"
$pullRequest.targetRefName = "refs/heads/$targetBranchName"

$pullRequest.reviewers += @{ id = $reviewerId }

$pullRequestUrl = $context.orgBaseUrl + '/git/repositories/' + $repo.id + '/pullrequests?api-version=' + $context.apiVersion
Write-Host $projectsUrl

$data = $pullRequest | ConvertTo-Json -Depth 10

if($context.isOnline) {
    $newPullRequest = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $pullRequestUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $newPullRequest = Invoke-RestMethod -Uri $pullRequestUrl -UseDefaultCredentials -Method Post -Body $data -ContentType $contentType
}

return $newPullRequest

}
# . .\AzureDevOpsContext.ps1

Function Import-ReleaseDef
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$jsonDefFilePath,
    [Parameter(Mandatory=$true)][string]$releaseDefName,
    [Parameter(Mandatory=$true)][string]$projectId,
    [Parameter(Mandatory=$true)][string]$buildDefId,
    [Parameter(Mandatory=$true)][string]$buildDefName,
    [Parameter(Mandatory=$true)][string]$ownerId,
    [Parameter(Mandatory=$true)][string]$approverId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$json = Get-Content -Path $jsonDefFilePath -Raw
$releaseDef = ConvertFrom-Json -InputObject $json
$releaseDef.name = $releaseDefName
$releaseDef.artifacts[0].sourceId = "$($projectId):$($buildDefId)"
$releaseDef.artifacts[0].alias = "_$($buildDefName)"
$releaseDef.artifacts[0].definitionReference.definition.id = $buildDefId
$releaseDef.artifacts[0].definitionReference.definition.name = $buildDefName
$releaseDef.artifacts[0].definitionReference.project.id = $projectId
$releaseDef.environments | ForEach-Object { 
    $_.deployPhases[0].deploymentInput.queueId = $null
    $_.owner.id = $ownerId
}
if($releaseDef.environments.length -gt 0) {
    $releaseDef.environments[1].preDeployApprovals.approvals[0].approver.id = $approverId
}
$releaseDef.triggers[0].artifactAlias = "_$($buildDefName)"
$releaseDef.id = $null

$contentType = 'application/json'

$releaseDefUrl = $context.projectBaseUrl + '/release/definitions?api-version=' + $context.apiVersion
Write-Host $releaseDefUrl

$data = ConvertTo-Json -InputObject $releaseDef -Depth 100

if($context.isOnline) {
    $newReleaseDef = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $releaseDefUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $newReleaseDef = Invoke-RestMethod -Uri $releaseDefUrl -UseDefaultCredentials -Method Post -Body $data -ContentType $contentType
}

return $newReleaseDef

}
# . .\AzureDevOpsContext.ps1

Function Import-SimpleReleaseDef
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$jsonDefFilePath,
    [Parameter(Mandatory=$true)][string]$releaseDefName,
    [Parameter(Mandatory=$true)][string]$ownerId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$json = Get-Content -Path $jsonDefFilePath -Raw
$releaseDef = ConvertFrom-Json -InputObject $json
$releaseDef.name = $releaseDefName
$releaseDef.environments | ForEach-Object { 
    $_.deployPhases[0].deploymentInput.queueId = $null
    $_.owner.id = $ownerId
}
$releaseDef.id = $null

$contentType = 'application/json'

$releaseDefUrl = $context.projectBaseUrl + '/release/definitions?api-version=' + $context.apiVersion
Write-Host $releaseDefUrl

$data = ConvertTo-Json -InputObject $releaseDef -Depth 100

if($context.isOnline) {
    $newReleaseDef = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $releaseDefUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $newReleaseDef = Invoke-RestMethod -Uri $releaseDefUrl -UseDefaultCredentials -Method Post -Body $data -ContentType $contentType
}

return $newReleaseDef

}
# . .\AzureDevOpsContext.ps1

Function Import-TaskGroup
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$jsonDefFilePath,
    [Parameter(Mandatory=$true)][string]$taskGroupName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$json = Get-Content -Path $jsonDefFilePath -Raw
$taskGroupDef = ConvertFrom-Json -InputObject $json
$taskGroupDef.name = $taskGroupName
$taskGroupDef.friendlyName = $taskGroupName

$contentType = 'application/json'
$v = $context.apiVersion + '-preview.1'

$taskGroupUrl = $context.projectBaseUrl + '/distributedtask/taskgroups?api-version=' + $v
Write-Host $taskGroupUrl

$data = ConvertTo-Json -InputObject $taskGroupDef -Depth 100

if($context.isOnline) {
    $newTaskGroup = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $taskGroupUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $newTaskGroup = Invoke-RestMethod -Uri $taskGroupUrl -UseDefaultCredentials -Method Post -Body $data -ContentType $contentType
}

return $newTaskGroup

}
Function Invoke-CloneRepo
{
    [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]
    $pat,
    [Parameter(Mandatory=$true)]
    [string]
    $repoUrl,
    [Parameter(Mandatory=$true)]
    [string]
    $localDir
)

$encodedPat = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(':' + $pat))

$cmd = 'git -c http.' + $repoUrl + '.extraheader="AUTHORIZATION:Basic ' + $encodedPat + '" clone ' + $repoUrl + ' --no-checkout --branch master "' + $localDir + '"'

Write-Host $repoUrl
Write-Host $cmd

cmd.exe /c $cmd

}

# . .\AzureDevOpsContext.ps1

Function Merge-VarGroupVars
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter()][string]$varGroupId,
    [Parameter()][string]$varGroupName,
    [Parameter()][string]$description,
    [Parameter(Mandatory=$true)][hashtable]$vars,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'
$v = $context.apiVersion + '-preview.2'

if([string]::IsNullOrEmpty($varGroupId)) {
    $varGroup = Get-VarGroupByName -varGroupName $varGroupName -context $context
    $varGroupId = $varGroup.id
}

$varGroupsUrl = $context.orgBaseUrl + '/distributedtask/variablegroups/' + $varGroupId + '?api-version=' + $v
$varGroupsUrl

$project = Get-Project -projectName $context.project -context $context
$existingVars = Get-VarGroupVars -varGroupName $varGroupName -context $context

$varsData = @{}
$existingVars.Keys | ForEach-Object { 
    $key = $_
    $updatedKey = $vars.Keys | Where-Object { $_ -eq $key }
    if($null -ne $updatedKey) {
        $value = $vars.Item($key)
    }
    else {
        $value = $existingVars.Item($key)
    }
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
    $varGroup = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $varGroupsUrl -Method Put -Body $data -ContentType $contentType
}
else {
    $varGroup = Invoke-RestMethod -Uri $varGroupsUrl -UseDefaultCredentials -Method Put -Body $data -ContentType $contentType
}

return $varGroup

}
class PermissionsReportResource {
    [string]$resourceId
    [string]$resourceName
    [ValidateSet('collection', 'project', 'projectGit', 'ref', 'release', 'repo', 'tfvc')]
    [string]$resourceType 
}
Function Push-GitChanges
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$repoName,
    [Parameter(Mandatory=$true)][string]$customerTenant,
    [Parameter(Mandatory=$true)][string]$srcDir,
    [Parameter(Mandatory=$true)][string]$commitMessage
)

$currentLocation = Get-Location

$dirName = $srcDir # [System.IO.Path]::Combine($srcDir, $customerTenant, $repoName)
$dir = Get-Item $dirName -ErrorAction SilentlyContinue

if($null -eq $dir) {
    Write-Host "Folder $dirName does not exist. You must create the repo and clone it locally first."
    exit
}
else {

    $cmd = 'cd ' + $dirName + '
git rev-parse --is-inside-work-tree'
    $result = Invoke-Expression $cmd
    if($result -ne 'true') {
        Write-Host 'Folder ' $dirName ' is not a GIT repo. You must create the repo and clone it locally first.'
    }
    else {
        $cmd = '
        git add .
        git commit -m "' + $commitMessage + '"
        git push origin master
        '
        Invoke-Expression $cmd
    }
}

Set-Location $currentLocation

}
# . .\AzureDevOpsContext.ps1

Function Remove-BuildDef
{
    [CmdletBinding()]
param(
    [Parameter()][string]$buildDefId,
    [Parameter()][string]$buildDefName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

if([string]::IsNullOrEmpty($buildDefId)) {
    $buildDef = Get-BuildDefByName -releaseDefName $buildDefName -context $context
    $buildDefId = $buildDef.id
}
$buildDefUrl = $context.projectBaseUrl + '/build/definitions/' + $buildDefId + '?api-version=' + $context.apiVersion
Write-Host $buildDefUrl

if($context.isOnline) {
    $result = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $buildDefUrl -Method Delete
}
else {
    $result = Invoke-RestMethod -Uri $buildDefUrl -UseDefaultCredentials -Method Delete
}

return $result

}
# . .\AzureDevOpsContext.ps1

Function Remove-GitRepo
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$repoId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$gitRepoUrl = $context.projectBaseUrl + '/git/repositories/' + $repoId + '?api-version=' + $context.apiVersion
Write-Host $gitRepoUrl
if($context.isOnline) {
    $repoResponse = Invoke-WebRequest -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $gitRepoUrl -Method Delete
}
else {
    $repoResponse = Invoke-WebRequest -Uri $gitRepoUrl -UseDefaultCredentials -Method Delete
}
$repoResponse

}
# . .\AzureDevOpsContext.ps1

Function Remove-GitRepoBranchPolicy
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$policyId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)


$configUrl = $context.projectBaseUrl + '/policy/configurations/' + $policyId + '?api-version=' + $context.apiVersion
Write-Host $configUrl
if($context.isOnline) {
    $response = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $configUrl -Method Delete
}
else {
    $response = Invoke-RestMethod -Uri $configUrl -Method Delete -UseDefaultCredentials
}
return $response

}
# . .\AzureDevOpsContext.ps1
# . .\Get-Group.ps1

Function Remove-GroupMembership
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$projectName,
    [Parameter(Mandatory=$true)][string]$groupName,
    [Parameter(Mandatory=$true)][string]$containerName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'
$graphCtx = Get-AzureDevOpsContext -protocol https -coreServer vssps.dev.azure.com -org $context.org -project $context.project -apiVersion $context.apiVersion `
    -pat $context.pat -isOnline

$group = Get-Group -projectName $projectName -groupName $groupName -context $context
Write-Host "Group: $group"
$container = Get-Group -projectName $projectName -groupName $containerName -context $context
Write-Host "Container: $container"

$membershipUrl = $graphCtx.orgBaseUrl + '/graph/memberships/' + $group.descriptor + '/' + $container.descriptor + '?api-version=' + $v
$membershipUrl

if($context.isOnline) {
    $response = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $membershipUrl -Method Delete
}
else {
    $response = Invoke-RestMethod -Uri $membershipUrl -UseDefaultCredentials -Method Delete
}

return $response

}
# . .\AzureDevOpsContext.ps1

Function Remove-PoolAgentByName
{
    [CmdletBinding()]
param(
    [Parameter()][string]$poolId,
    [Parameter()][string]$poolName,
    [Parameter()][string]$agentName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

if([string]::IsNullOrEmpty($poolId)) {
    $pool = Get-PoolByName -poolName $poolName -context $context
    $poolId = $pool.id
}

$v = $context.apiVersion + '-preview.1'

$agent = Get-PoolAgentByName -poolId $poolId -agentName $agentName -context $context
$agentId = $agent.id

$agentUrl = $context.orgBaseUrl + '/distributedtask/pools/' + $poolId + '/agents/' + $agentId + '?api-version=' + $v
$agentUrl


if($context.isOnline) {
    $result = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $agentUrl -Method Delete
}
else {
    $result = Invoke-RestMethod -Uri $agentUrl -UseDefaultCredentials -Method Delete
}

return $result

}
Function Remove-PoolAgentsByStatus {

param(
    [ValidateNotNullOrEmpty()]
    [Parameter()][string]$poolId,
    [Parameter()][string]$poolName,
    [ValidateSet("online", "offline")]
    [Parameter(Mandatory=$true)][string]$status,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

if([string]::IsNullOrEmpty($poolId)) {
    $pool = Get-PoolByName -poolName $poolName -context $context
    $poolId = $pool.id
}

$v = $context.apiVersion + '-preview.1'
$agentsUrl = $context.orgBaseUrl + '/distributedtask/pools/' + $poolId + '/agents/?api-version=' + $v
$agentsUrl


if($isOnline) {
    $agents = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $agentsUrl
}
else {
    $agents = Invoke-RestMethod -Uri $agentsUrl -UseDefaultCredentials
}

$agents.value | ForEach-Object {

if($_.status -eq $status) {

    $agentId = $_.id

    $agentUrl = $context.orgBaseUrl + '/distributedtask/pools/' + $poolId + '/agents/' + $agentId + '?api-version=' + $v
    $agentUrl


    if($context.isOnline) {
        $result = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $agentUrl -Method Delete
    }
    else {
        $result = Invoke-RestMethod -Uri $agentUrl -UseDefaultCredentials -Method Delete
    }

    $result

}

}

}
# . .\AzureDevOpsContext.ps1
# . .\Get-Project.ps1

Function Remove-Project
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$name,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$project = Get-Project -projectName $name -context $context
$projectUrl = $context.orgBaseUrl + '/projects/' + $project.id + '?api-version=' + $context.apiVersion
Write-Host $projectUrl

if($context.isOnline) {
    $response = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $projectUrl -Method Delete
}
else {
    $response = Invoke-RestMethod -Uri $projectUrl -UseDefaultCredentials -Method Delete
}

return $response

}
# . .\AzureDevOpsContext.ps1

Function Remove-ReleaseDef
{
    [CmdletBinding()]
param(
    [Parameter()][string]$releaseDefId,
    [Parameter()][string]$releaseDefName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

if([string]::IsNullOrEmpty($releaseDefId)) {
    $releaseDef = Get-ReleaseDefByName -releaseDefName $releaseDefName -context $context
    $releaseDefId = $releaseDef.id
}
$releaseDefUrl = $context.projectBaseUrl + '/release/definitions/' + $releaseDefId + '?api-version=' + $context.apiVersion
Write-Host $releaseDefUrl

if($context.isOnline) {
    $result = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $releaseDefUrl -Method Delete
}
else {
    $result = Invoke-RestMethod -Uri $releaseDefUrl -UseDefaultCredentials -Method Delete
}

return $result

}
# . .\AzureDevOpsContext.ps1
# . .\Get-Project.ps1
Function Remove-ServiceEndpoint
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter()][string]$endpointId,
    [Parameter()][string]$endpointName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

if([string]::IsNullOrEmpty($endpointId)) {
  $endpoint = Get-ServiceEndpointByName -endpointName $endpointName -context $context
  $endpointId = $endpoint.id
}
$project = Get-Project -projectName $context.project -context $context

$v = $context.apiVersion + '-preview.4'
$endpointUrl = $context.orgBaseUrl + '/serviceendpoint/endpoints/' + $endpointId + '?projectIds=' + $project.id + '&api-version=' + $v

if($context.isOnline) {
    $result = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $endpointUrl -Method Delete
}
else {
    $result = Invoke-RestMethod -Uri $endpointUrl -UseDefaultCredentials -Method Delete
}

return $result

}
# . .\AzureDevOpsContext.ps1
# . .\Get-Group.ps1
# . .\Get-User.ps1

Function Remove-UserEntitlements
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$userName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.3'
$entitlementsCtx = Get-AzureDevOpsContext -protocol https -coreServer vsaex.dev.azure.com -org $context.org -project $context.project -apiVersion $context.apiVersion `
    -pat $context.pat -isOnline

$user = Get-User -userName $userName -context $context
Write-Host $user

$entitlementsUrl = $entitlementsCtx.orgBaseUrl + '/userentitlements/' + $user.originId + '?api-version=' + $v
$entitlementsUrl

if($context.isOnline) {
    $response = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $entitlementsUrl -Method Delete
}
else {
    $response = Invoke-RestMethod -Uri $entitlementsUrl -UseDefaultCredentials -Method Delete
}

return $response

}
# . .\AzureDevOpsContext.ps1
# . .\Get-Group.ps1
# . .\Get-User.ps1

Function Remove-UserMembership
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$projectName,
    [Parameter(Mandatory=$true)][string]$userName,
    [Parameter(Mandatory=$true)][string]$containerName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'
$graphCtx = Get-AzureDevOpsContext -protocol https -coreServer vssps.dev.azure.com -org $context.org -project $context.project -apiVersion $context.apiVersion `
    -pat $context.pat -isOnline

$user = Get-User -userName $userName -context $context
Write-Host $user
$container = Get-Group -projectName $projectName -groupName $containerName -context $context
Write-Host $container

$membershipUrl = $graphCtx.orgBaseUrl + '/graph/memberships/' + $user.descriptor + '/' + $container.descriptor + '?api-version=' + $v
$membershipUrl

if($context.isOnline) {
    $response = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $membershipUrl -Method Delete
}
else {
    $response = Invoke-RestMethod -Uri $membershipUrl -UseDefaultCredentials -Method Delete
}

return $response

}
Function Restore-GitRepo {
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory = $true)][string]$repoBackupPath,
        [Parameter(Mandatory = $true)][string]$repoName,
        [Parameter()][switch]$expand,
        [Parameter(Mandatory = $true)][AzureDevOpsContext]$context
    )


    $orig = Get-Location

    if($expand) {
        if(!(Test-Path $repoBackupPath -PathType Leaf))
        {
            throw "$repoBackupPath doesn't exist."
        }
    }
    else {
        if(!(Test-Path $repoBackupPath))
        {
            throw "$repoBackupPath doesn't exist."
        }
    }

    if($expand) {
        $repoBackupDirPath = [IO.Path]::GetDirectoryName($repoBackupPath)
        Expand-Archive -Path $repoBackupPath -DestinationPath $repoBackupDirPath -Force
        $gitPath = (Get-ChildItem -Path $repoBackupDirPath -Depth 2)[2].FullName # expects {old repo name}.git folder
        if(!(Test-Path $gitPath))
        {
            throw "$gitPath doesn't exist."
        }
        Set-Location $gitPath
    }
    else {
        Set-Location $repoBackupPath
    }

    $repoUrl = $context.protocol + "://" + $context.org + "@dev.azure.com/" + $context.org + "/" + $context.project + "/_git/" + $repoName

    git push --mirror $repoUrl

    Set-Location $orig
}
# . .\AzureDevOpsContext.ps1

Function Set-BuildDef
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][int]$buildDefId,
    [Parameter(Mandatory=$true)][hashtable]$buildDef,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)


$contentType = 'application/json'

$buildDefUrl = $context.projectBaseUrl + '/build/definitions/' + $buildDefId + '?api-version=' + $context.apiVersion
Write-Host $buildDefUrl

$data = ConvertTo-Json -InputObject $buildDef -Depth 100

if($context.isOnline) {
    $newBuildDef = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $buildDefUrl -Method Put -Body $data -ContentType $contentType
}
else {
    $newBuildDef = Invoke-RestMethod -Uri $buildDefUrl -UseDefaultCredentials -Method Put -Body $data -ContentType $contentType
}

return $newBuildDef

}
# . .\AzureDevOpsContext.ps1

Function Set-BuildDefProperty
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][int]$buildDefId,
    [ValidateSet("add", "remove", "replace")]
    [Parameter(Mandatory=$true)][string]$op,
    [Parameter(Mandatory=$true)][string]$propertyPath,
    [Parameter(Mandatory=$true)][string]$propertyValue,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json-patch+json'
$v = $context.apiVersion + '-preview.1'

$buildDefUrl = $context.projectBaseUrl + '/build/definitions/' + $buildDefId + '/properties?api-version=' + $v
Write-Host $buildDefUrl

$props = @(
    @{
        op = $op;
        path = $propertyPath;
        value = $propertyValue
    }
)
$data = ConvertTo-Json -InputObject $props -Depth 10

if($context.isOnline) {
    $result = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $buildDefUrl -Method Patch -Body $data -ContentType $contentType
}
else {
    $result = Invoke-RestMethod -Uri $buildDefUrl -UseDefaultCredentials -Method Patch -Body $data -ContentType $contentType
}

return $result

}
# . .\AzureDevOpsContext.ps1

Function Set-FeedRetentionPolicy
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$feedId,
    [Parameter()][switch]$orgLevel,
    [Parameter(Mandatory=$true)][int]$countLimit,
    [Parameter(Mandatory=$true)][int]$daysToKeepRecentlyDownloadedPackages,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'
$v = $context.apiVersion + '-preview.1'

if($orgLevel) {
    $retentionPolicyUrl = $context.orgBaseUrl + '/packaging/Feeds/' + $feedId + '/retentionpolicies?api-version=' + $v
}
else {
    $retentionPolicyUrl = $context.projectBaseUrl + '/packaging/Feeds/' + $feedId + '/retentionpolicies?api-version=' + $v
}
$retentionPolicyUrl


$data = @{
    countLimit = $countLimit;
    daysToKeepRecentlyDownloadedPackages = $daysToKeepRecentlyDownloadedPackages;

} | ConvertTo-Json -Depth 10

if($context.isOnline) {
    $retentionPolicy = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $retentionPolicyUrl -Method Put -Body $data -ContentType $contentType
}
else {
    $retentionPolicy = Invoke-RestMethod -Uri $retentionPolicyUrl -UseDefaultCredentials -Method Put -Body $data -ContentType $contentType
}

return $retentionPolicy

}
# . .\AzureDevOpsContext.ps1

Function Set-GitRepoBranchLock
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$repositoryId,
    [Parameter(Mandatory=$true)][string]$branchName,
    [Parameter(Mandatory=$true)][bool]$lock, # $true for lock, $false for unlock
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'


$cfg = @{
  isLocked = $lock;
}
  
$data = ConvertTo-Json -InputObject $cfg -Depth 10

$configUrl = $context.projectBaseUrl + '/git/repositories/' + $repositoryId + '/refs?filter=' + $branchName + '&api-version=' + $context.apiVersion
Write-Host $configUrl
if($context.isOnline) {
    $response = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $configUrl -Method Patch -Body $data -ContentType $contentType
}
else {
    $response = Invoke-RestMethod -Uri $configUrl -Method Patch -Body $data -ContentType $contentType -UseDefaultCredentials
}
return $response

}
# . .\AzureDevOpsContext.ps1

Function Set-GroupAvatar
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$projectName,
    [Parameter(Mandatory=$true)][string]$groupName,
    [Parameter(Mandatory=$true)][string]$filePath,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'
$v = $context.apiVersion + '-preview.1'

$graphCtx = Get-AzureDevOpsContext -protocol https -coreServer vssps.dev.azure.com -org $context.org -project $context.project -apiVersion $context.apiVersion `
    -pat $context.pat -isOnline
$v = $context.apiVersion + '-preview.1'
$group = Get-Group -projectName $projectName -groupName $groupName -context $context

$avatarUrl = $graphCtx.orgBaseUrl + '/graph/Subjects/' + $group.descriptor + '/avatars?api-version=' + $v
Write-Host $avatarUrl

# $imageData = [Convert]::ToBase64String((Get-Content $filePath -Encoding Byte))
[byte[]]$imageData = Get-Content $filePath -Encoding byte
$timestamp = Get-Date -Format o | ForEach-Object { $_ -replace ":", "." }
$objs = @(
    @{
        isAutoGenerated = $false;
        timeStamp = $timestamp;
        size = 1; # 'small';
        value = $imageData;
    },
    @{
        isAutoGenerated = $false;
        timeStamp = $timestamp;
        size = 2; # 'medium';
        value = $imageData;
    },
    @{
        isAutoGenerated = $false;
        timeStamp = $timestamp;
        size = 3; # 'large';
        value = $imageData;
    }
)
$objs | ForEach-Object {

    $obj = $_
    $data = ConvertTo-Json -InputObject $obj -Depth 10
    if($context.isOnline) {
        Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $avatarUrl -Method Put -Body $data -ContentType $contentType
    }
    else {
        Invoke-RestMethod -Uri $avatarUrl -UseDefaultCredentials -Method Put -Body $data -ContentType $contentType
    }
    # Start-Sleep -Milliseconds 1000

}

}
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
# . .\AzureDevOpsContext.ps1
# . .\Get-Group.ps1

Function Set-GroupMembership
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$projectName,
    [Parameter(Mandatory=$true)][string]$groupName,
    [Parameter(Mandatory=$true)][string]$containerName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'
$graphCtx = Get-AzureDevOpsContext -protocol https -coreServer vssps.dev.azure.com -org $context.org -project $context.project -apiVersion $context.apiVersion `
    -pat $context.pat -isOnline

$group = Get-Group -projectName $projectName -groupName $groupName -context $context
Write-Host $group
$container = Get-Group -projectName $projectName -groupName $containerName -context $context
Write-Host $container

$membershipUrl = $graphCtx.orgBaseUrl + '/graph/memberships/' + $group.descriptor + '/' + $container.descriptor + '?api-version=' + $v
$membershipUrl

if($context.isOnline) {
    $response = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $membershipUrl -Method Put
}
else {
    $response = Invoke-RestMethod -Uri $membershipUrl -UseDefaultCredentials -Method Put
}

return $response

}
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


# . .\AzureDevOpsContext.ps1

Function Set-GroupPermissionAzDevOpsCli
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$groupName,
    # for list of namespaces, use: az devops security permission namespace list --query "[].name"
    # for both ids and names, use: az devops security permission namespace list --query "[].{ namespaceId: namespaceId, name: name}"
    [Parameter()][string]$namespaceName,
    [Parameter()][string]$namespaceId,
    # for list of actions for a namespace, use: az devops security permission namespace list --query "[?@.name == '$namespaceName'].actions" 
    [Parameter(Mandatory=$true)][string]$actionName, 
    # Security token for the namespace, see this link for token guidance:
    # https://docs.microsoft.com/en-us/azure/devops/cli/security_tokens?view=azure-devops
    [Parameter(Mandatory=$true)][string]$securityToken, 
    [Parameter()][bool]$toggleAllow, #  $true for allow, $false for deny; use without $reset switch
    [Parameter()][switch]$reset, #  if used, reset the permission
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$currentLocation = Get-Location

$org = $context.org
$projName = $context.project

Set-Location $env:USERPROFILE

$subject = az devops security group list `
    --org "https://dev.azure.com/$org/" `
    --scope project `
    --project "$projName" `
    --subject-types vssgp `
    --query "graphGroups[?@.principalName == '[$projName]\$groupName'].descriptor | [0]"
Write-Host "subject: $subject"
 
if([String]::IsNullOrEmpty($namespaceId)) {
    $namespaceId = az devops security permission namespace list `
        --org "https://dev.azure.com/$org/" `
        --query "[?@.name == '$namespaceName'].namespaceId | [0]"
}
Write-Host "namespaceId: $namespaceId"

$bit = az devops security permission namespace show `
    --namespace-id $namespaceId `
    --org "https://dev.azure.com/$org/" `
    --query "[0].actions[?@.name == '$actionName'].bit | [0]"
Write-Host "bit: $bit"

if($reset) {
    az devops security permission reset `
    --id $namespaceId `
    --subject $subject `
    --token $securityToken `
    --permission-bit $bit `
    --org https://dev.azure.com/$org/ `
    --debug

}
else {
if($toggleAllow) {
        az devops security permission update `
            --id $namespaceId `
            --subject $subject `
            --token $securityToken `
            --allow-bit $bit `
            --merge true `
            --org https://dev.azure.com/$org/ `
            --debug
    }
    else {
        az devops security permission update `
            --id $namespaceId `
            --subject $subject `
            --token $securityToken `
            --deny-bit $bit `
            --merge true `
            --org https://dev.azure.com/$org/ `
            --debug
    }
}
Set-Location $currentLocation

}


# . .\AzureDevOpsContext.ps1
# copy a task group to a destination org / project
# requires source task groups to be loaded
# goes recursively through and identifies dependencies (aka task groups within task groups) and creates them
# it doesn't check if the underlying tasks exist in the destination org

Function Set-TaskGroup
{
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$true)][PSCustomObject]$taskGroup,
        [Parameter(Mandatory=$true)][PSCustomObject[]]$srcTaskGroups,
        [Parameter(Mandatory=$true)][AzureDevOpsContext]$destCtx
    )
    
    $metaTasks = $taskGroup.tasks | Where-Object { $_.task.definitionType -eq 'metaTask' }
    if(0 -ne $metaTasks.Length) {
        $metaTasks | ForEach-Object {
            $metaTask = $_
            $taskGroup1 = $srcTaskGroups | Where-Object { $_.id -eq $metaTask.task.id }
            if($null -ne $taskGroup1) {
                $destTaskGroup = Set-TaskGroup -taskGroup $taskGroup1 -srcTaskGroups $srcTaskGroups -destCtx $destCtx
                # map the meta task ID to the new task ID from dest
                $taskGroup.tasks | Where-Object { $_id.task.id -eq $metaTask.id } | ForEach-Object {
                    $_.task.id = $destTaskGroup.id
                }
            }
        }
    }
    $destTaskGroup = Get-TaskGroupByName -taskGroupName $taskGroup.name -context $destCtx
    if($null -eq $destTaskGroup) {
        $destTaskGroup = Add-TaskGroup -taskGroup $taskGroup -context $destCtx
    }
    return $destTaskGroup
}
# . .\AzureDevOpsContext.ps1
# . .\Get-Group.ps1
# . .\Get-User.ps1

Function Set-UserMembership
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$projectName,
    [Parameter(Mandatory=$true)][string]$userName,
    [Parameter(Mandatory=$true)][string]$containerName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'
$graphCtx = Get-AzureDevOpsContext -protocol https -coreServer vssps.dev.azure.com -org $context.org -project $context.project -apiVersion $context.apiVersion `
    -pat $context.pat -isOnline

$user = Get-User -userName $userName -context $context
Write-Host $user
if ($null -eq $user) {
    throw "User $userName doesn't exist."
}
$container = Get-Group -projectName $projectName -groupName $containerName -context $context
if ($null -eq $container) {
    throw "Group $containerName doesn't exist."
}
Write-Host $container

$membershipUrl = $graphCtx.orgBaseUrl + '/graph/memberships/' + $user.descriptor + '/' + $container.descriptor + '?api-version=' + $v
$membershipUrl

if($context.isOnline) {
    $response = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $membershipUrl -Method Put
}
else {
    $response = Invoke-RestMethod -Uri $membershipUrl -UseDefaultCredentials -Method Put
}

return $response

}
# . .\AzureDevOpsContext.ps1

Function Set-UsersMembershipFromFile 
{
    param(
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$true)][string]$projectName,
        [Parameter(Mandatory=$true)][string]$filePath,
        [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
    )

    $data = Import-Csv -Path $filePath
    # assumes the header is UserName,GroupName
    $data | ForEach-Object {
        $userName = $_.UserName
        $groupName = $_.GroupName
        Set-UserMembership -projectName $projectName -userName $userName -containerName $groupName -context $context
    }
}
# . .\AzureDevOpsContext.ps1

Function Set-VarGroupVars
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter()][string]$varGroupId,
    [Parameter()][string]$varGroupName,
    [Parameter()][string]$description,
    [Parameter(Mandatory=$true)][hashtable]$vars,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'
$v = $context.apiVersion + '-preview.2'

if([string]::IsNullOrEmpty($varGroupId)) {
    $varGroup = Get-VarGroupByName -varGroupName $varGroupName -context $context
    $varGroupId = $varGroup.id
}

$varGroupsUrl = $context.orgBaseUrl + '/distributedtask/variablegroups/' + $varGroupId + '?api-version=' + $v
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
    $varGroup = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $varGroupsUrl -Method Put -Body $data -ContentType $contentType
}
else {
    $varGroup = Invoke-RestMethod -Uri $varGroupsUrl -UseDefaultCredentials -Method Put -Body $data -ContentType $contentType
}

return $varGroup

}
# . .\AzureDevOpsContext.ps1

Function Set-WIT
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$processId,
    [Parameter(Mandatory=$true)][string]$witRefName,
    [Parameter(Mandatory=$true)][hashtable]$wit,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)


$contentType = 'application/json-patch+json'

$witUrl = $context.orgBaseUrl + '/work/processes/' + $processId + '/workitemtypes/' + $witRefName + '?api-version=' + $context.apiVersion
Write-Host $witUrl

$data = ConvertTo-Json -InputObject $wit -Depth 10

if($context.isOnline) {
    $newWit = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $witUrl -Method Patch -Body $data -ContentType $contentType
}
else {
    $newWit = Invoke-RestMethod -Uri $witUrl -UseDefaultCredentials -Method Patch -Body $data -ContentType $contentType
}

return $newWit

}
Function Start-Build
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter()][string]$buildDefId,
    [Parameter()][string]$buildDefName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)
$contentType = 'application/json'

if([string]::IsNullOrEmpty($buildDefId)) {
    $buildDef = Get-BuildDefByName -buildDefName $buildDefName -context $context
    $buildDefId = $buildDef.id
}

$buildsUrl = $context.projectBaseUrl + '/build/builds?api-version=' + $context.apiVersion
$buildsUrl

$data = @{
    definition = @{
        id = $buildDefId;
    }
} | ConvertTo-Json -Depth 10

if($context.isOnline) {
    $response = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $buildsUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $response = Invoke-RestMethod -Uri $buildsUrl -UseDefaultCredentials -Method Post -Body $data -ContentType $contentType
}
return $response

}
# . .\Build-Signature.ps1
Function Submit-LogAnalyticsData($customerId, $sharedKey, $body, $logType) {
    $method = "POST"
    $contentType = "application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString("r")
    $contentLength = $body.Length
    $signature = Build-Signature `
        -customerId $customerId `
        -sharedKey $sharedKey `
        -date $rfc1123date `
        -contentLength $contentLength `
        -method $method `
        -contentType $contentType `
        -resource $resource
    $uri = "https://" + $customerId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"
  
    $headers = @{
        "Authorization"        = $signature;
        "Log-Type"             = $logType;
        "x-ms-date"            = $rfc1123date;
        "time-generated-field" = $TimeStampField;
    }
  
    $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing
    return $response.StatusCode
  
}

Function Sync-GitRepo
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$repoName,
    [Parameter(Mandatory=$true)][string]$customerTenant,
    [Parameter(Mandatory=$true)][string]$srcDir
)

$currentLocation = Get-Location

$dirName = $srcDir # [System.IO.Path]::Combine($srcDir, $customerTenant, $repoName)
$dir = Get-Item $dirName -ErrorAction SilentlyContinue

if($null -eq $dir) {
    Write-Host "Folder $dirName does not exist. You must create the repo and clone it locally first."
    exit
}
else {

    $cmd = 'cd ' + $dirName + '
git rev-parse --is-inside-work-tree'
    $result = Invoke-Expression $cmd
    if($result -ne 'true') {
        Write-Host 'Folder ' $dirName ' is not a GIT repo. You must create the repo and clone it locally first.'
    }
    else {
        $cmd = '
git pull upstream master --allow-unrelated-histories
git pull origin master
        '
        Invoke-Expression $cmd
    }
}

Set-Location $currentLocation

}
# . .\AzureDevOpsContext.ps1

Function Sync-NugetPackage
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$feedId,
    [Parameter(Mandatory=$true)][string]$packageName,
    [Parameter()][string]$packageVersion,
    [ValidateSet("nuget", "npm")]
    [Parameter(Mandatory=$true)][string]$protocolType,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$v = $context.apiVersion + '-preview.1'

if([string]::IsNullOrEmpty($packageVersion)) {
    $package = Get-FeedPackageByName -feedId $feedId -packageName $packageName -protocolType $protocolType -context $context
    $packageVersion = ($package.value[0].versions | Sort-Object -Property publishDate -Descending)[0].version
}

$packageUrl = "$($context.projectBaseUrl)/packaging/feeds/$feedId/$protocolType/packages/$packageName/versions/$packageVersion/content?api-version=$v"
Write-Host $packageUrl

if($context.isOnline) {
    $result = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $packageUrl -Method Head
}
else {
    $result = Invoke-RestMethod -Uri $packageUrl -UseDefaultCredentials -Method Head
}

return $result

}
Function Test-GitVSSolution
{
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$repoName,
    [Parameter(Mandatory=$true)][string]$customerTenant,
    [Parameter(Mandatory=$true)][string]$srcDir
)

$currentLocation = Get-Location

$dirName = $srcDir # [System.IO.Path]::Combine($srcDir, $customerTenant, $repoName)
$dir = Get-Item $dirName -ErrorAction SilentlyContinue

if($null -eq $dir) {
    Write-Host "Folder $dirName does not exist. You must create the repo and clone it locally first."
    exit
}
else {

    $cmd = 'cd ' + $dirName + '
git rev-parse --is-inside-work-tree'
    $result = Invoke-Expression $cmd
    if($result -ne 'true') {
        Write-Host 'Folder ' $dirName ' is not a GIT repo. You must create the repo and clone it locally first.'
    }
    else {
        $apiDir = [System.IO.Path]::Combine($dirName, 'App.Api')
        $uiDir = [System.IO.Path]::Combine($dirName, 'App.UI')
        $frontUIDir = [System.IO.Path]::Combine($dirName, 'App.UI', 'app-ui')
        $cmd = '
        cd ' + $apiDir + '
        dotnet build
        '
        Invoke-Expression $cmd
        $cmd = '
        cd ' + $uiDir + '
        dotnet build
        '
        Invoke-Expression $cmd

        $cmd = '
        cd ' + $frontUIDir + '
        npm run build
        '
        Invoke-Expression $cmd

    }
}

Set-Location $currentLocation

}
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
