# Project On-Boarding PowerShell cmdlets

## Introduction

This is a list of PowerShell cmdlets which can be used for automation of Azure DevOps projects.
The PowerShell cmlets require Azure DevOps AuthN, using PAT (Personal Access Token).
Create your own PAT (it requires full access) and use it in the *project-onboarding.ps1* script.
The AuthN is stored in a context (see `AzureDevOpsContext` PowerShell object).
The cmdlets are organized as functions with one or more parameters.
Some hints:
 - `. .\script.ps1` - loads in memory the *script.ps1* from the current path
 - most of the functions require a `context` parameter of type `AzureDevOpsContext`
 - most of the functions use Azure DevOps REST API; however, some of the features are only available via the `az devops` CLIs (`Add-Group`, `Add-GroupPermission`, `Set-GroupMembership`, `Add-Feed`, `Add-UniversalPackage`, `Add-YamlPipeline`, etc.).
 - some features are in preview: `az devops security`, `az devops artifacts universal`

## List of PowerShell cmdlets

### AuthN context
An object instance of type `AzureDevOpsContext` stores AuthN information to an Azure DevOps organization / project
Properties:
 - `org` - Azure DevOps organization
 - `project` - Azure DevOps project
 - `protocol` - https | http - you can use http only for on-premises Azure DevOps server
 - `coreServer` - dev.azure.com (or the corresponding Azure DevOps Server on-prem url); in some cases, coreServer could have different values (for example, vsrm.dev.azure.com for Release Management)
 - `apiVersion` - Azure DevOps REST API version (could be 5.0, 5.1, 6.0); the current stable version used by the cmdlets is 5.1; some cmdlets use APIs in preview, and they add the preview information to the patch component (i.e. 5.1-preview.1)
 - `orgBaseUrl` - the base API Url for organisation - https://dev.azure.com/{org}/_apis
 - `orgUrl` - the base Url for organisation - https://dev.azure.com/{org}
 - `projectBaseUrl` - the base API Url for project - https://dev.azure.com/{org}/{project}/_apis
 - `projectUrl` - the base Url for project - https://dev.azure.com/{org}/{project}
 - `pat` - Personal Authentication Token provided
 - `base64AuthInfo` - the PAT in BASE64 format (required by the REST APIs)

### Get-AzureDevOpsContext
Create an Azure DevOps AuthN context. It doesn't perform AuthN, it only creates the `AzureDevOpsContext` instance. AuthN is performed by each individual function / cmdlet at runtime.

Example:

``` PowerShell
# . .\AzureDevOpsContext.ps1

$org = 'daradu'
$projName = 'ACC-003'
$repoName = "$projName-app"
$pat = '***'

# create an Azure DevOps context for AuthN
. .\Get-AzureDevOpsContext.ps1
$context = Get-AzureDevOpsContext -protocol https -coreServer dev.azure.com -org $org -project $projName -apiVersion 5.1 `
    -pat $pat -isOnline
```

### Get-Processes
Return the list of inherited processes available in the organization.

Example 
``` PowerShell
# get the list of processes; identify the Agile process ID and use it in the project creation step
. .\Get-Processes.ps1
$processes = Get-Processes -context $context
$processes.value | ForEach-Object { Write-Host $_.id $_.name }
```

### Add-Project
Create an Azure DevOps project using the corresponding process ID.

Example 
``` PowerShell
# create an Azure DevOps project based on the Agile process ID
. .\Add-Project.ps1
$projDescription = 'This project is for product 003.'
$processTemplateId = '***' # Agile
$project = Add-Project -name $projName -description $projDescription -processTemplateId $processTemplateId -context $context
```

### Add-Team
Create and Azure DevOps team.

Example
``` PowerShell
# create a Azure DevOps project team
. .\Add-Team.ps1
$teamName = 'Omega' #'Alpha' # 'Omega'
$team = Add-Team -name $teamName -description $teamName -context $context
$team
```

### Add-Group
Create an Azure DevOps Security Group.

Example
``` PowerShell
# create the required Azure DevOps groups 
. .\Add-Group.ps1
$groupName = 'Team Contributor'
$groupDescription = 'All contribution but read only for pipelines'
Add-Group -name $groupName -description $groupDescription -context $context
$groupName = "DevOps Engineer"
$groupDescription = "Author and execute pipelines, read only for source repository"
Add-Group -name $groupName -description $groupDescription -context $context
$groupName = 'Change Manager'
$groupDescription = 'This is for manual approval when moving through stage gates and deployment'
Add-Group -name $groupName -description $groupDescription -context $context
```

### Add-GroupPermission
Add permission to a particular Security Group. It requires a security namespace name or ID, the action name, and the security token. 
Check *security-namespaces.json* file for the list of namespaces.
Check *security-gitrepos-actions.json* for the list of actions for Git Repositories namespace.
Use this link for token guidance: https://docs.microsoft.com/en-us/azure/devops/cli/security_tokens?view=azure-devops

Example
``` PowerShell
# set the GenericContribute permission (allow or deny) on Git Repositories (project level) for the required groups
# check security-namespaces.json file for the list of namespaces 
# check security-gitrepos-actions.json for the list of actions for Git Repositories namespace
. .\Add-GroupPermission.ps1
. .\Get-Project.ps1
$namespaceName = 'Git Repositories'
$actionName = 'GenericContribute'
$proj = Get-Project -projectName $projName -context $context
# use this link for token guidance: https://docs.microsoft.com/en-us/azure/devops/cli/security_tokens?view=azure-devops

$securityToken = "repoV2/$($proj.id)/"

$groupName = "Team Contributor" 
Add-GroupPermission -groupName $groupName -namespaceName $namespaceName -actionName $actionName -securityToken $securityToken -toggleAllow $true -context $context
$groupName = "DevOps Engineer"
Add-GroupPermission -groupName $groupName -namespaceName $namespaceName -actionName $actionName -securityToken $securityToken -toggleAllow $false -context $context
$groupName = "Change Manager"
Add-GroupPermission -groupName $groupName -namespaceName $namespaceName -actionName $actionName -securityToken $securityToken -toggleAllow $false -context $context




# set Release Management permissions for the required groups
# there are two namespaces identified by two different namespaceIds, but the same name (ReleaseManagement)
. .\Add-GroupPermission.ps1
. .\Get-Project.ps1
$proj = Get-Project -projectName $projName -context $context
# use this link for token guidance: https://docs.microsoft.com/en-us/azure/devops/cli/security_tokens?view=azure-devops
$securityToken = "$($proj.id)/"
@('c788c23e-1b46-4162-8f5e-d7585343b5de', '7c7d32f7-0e86-4cd6-892e-b35dbba870bd') | ForEach-Object {
    $namespaceId = $_
    $json = Get-Content -Path ".\security-releasemgmt-actions-$namespaceId.json" -Raw
    $actions = ConvertFrom-Json -InputObject $json
    $actions | ForEach-Object {
        $actionName = $_.name
        $allow = $actionName.StartsWith("View")
        $groupName = "Team Contributor" 
        Add-GroupPermission -groupName $groupName -namespaceId $namespaceId -actionName $actionName -securityToken $securityToken -toggleAllow $allow -context $context
        $groupName = "Change Manager"
        Add-GroupPermission -groupName $groupName -namespaceId $namespaceId -actionName $actionName -securityToken $securityToken -toggleAllow $allow -context $context
        $groupName = "DevOps Engineer"
        Add-GroupPermission -groupName $groupName -namespaceId $namespaceId -actionName $actionName -securityToken $securityToken -toggleAllow $true -context $context
    }
}

```

### Get-ProjectDescriptor
Get the security descriptor for a particular Azure DevOps project.

Example
``` PowerShell
# get project descriptor example
. .\Get-ProjectDescriptor.ps1
$descriptor = Get-ProjectDescriptor -projectName $projName -context $context
```

### Get-Groups
Return the list of Azure DevOps Security Porjects for the specified project.

Example
``` PowerShell
# get group list example
. .\Get-Groups.ps1
$groups = Get-Groups -projectName $projName -context $context
```

### Get-Group
Return the Security Group by name.

Example
``` PowerShell
# get group example
. .\Get-Group.ps1
$groupName = 'Alpha'
$group = Get-Group -projectName $projName -groupName $groupName -context $context
```

### Set-GroupMembership
Add the specified group as member to another Security Group (container).

Example
``` PowerShell
# set group membership (add one group as member of another group)
. .\Set-GroupMembership.ps1
$groupName = 'Omega' # 'Alpha' # 'Omega'
$containerName = 'Contributors'
Set-GroupMembership -projectName $projName -groupName $groupName -containerName $containerName -context $context
```

### Add-ClassificationNodes
Create Area Paths or Iterations based on information provided in a JSON file.
See *areas.json* or *iterations.json* files for the hierarchy structure examples.

Example
``` PowerShell
# add Area Paths (not required)
. .\Add-ClassificationNodes.ps1
$response = Add-ClassificationNodes -structureGroup 'areas' -jsonFilePath '.\areas.json' -context $context
$response

# add Iterations (not required)
$response = Add-ClassificationNodes -structureGroup 'iterations' -jsonFilePath '.\iterations.json' -context $context
$response
```

### Add-GitRepo
Create an empty Git repository.

Example
``` PowerShell
# create empty Git repository
. .\Add-GitRepo.ps1
$repo = Add-GitRepo -repoName $repoName -context $context
```

### Add-AspNetCoreGitRepoStructure
Create the basic structure for an ASP.NET Core Web App and pushes it into a Git repo.
The app template is based on `dotnet new` command. 

Example
``` PowerShell
# add repo structure based on ASP.NET Core WebApp template
. .\Add-AspNetCoreGitRepoStructure.ps1
$appName = 'WebApp3'
$srcDir = 'C:\Sources\ACC-003\master'
Add-AspNetCoreGitRepoStructure -repoName $repoName -appName $appName -srcDir $srcDir -context $context
```

### Get-RepoPolicyTypes
Return a list of policy types applicable to Git repositories.

Example
``` PowerShell
# get list of policy types example
. .\Get-RepoPolicyTypes.ps1
$policyTypes = Get-RepoPolicyTypes -context $context
$policyTypes | ConvertTo-Json -Depth 10 > "C:\Sources\ACC\Scripts\policyTypes.json"
```

### Get-GitRepo
Return a Git repo object based on its name.

Example
``` PowerShell
# get repo example
. .\Get-GitRepo
$repo = Get-GitRepo -repoName $repoName -context $context
```

### Add-GitRepoBranchPolicyApprover, Add-GitRepoBranchPolicyComment, Add-GitRepoBranchPolicyBuild
Various functions / cmdlets to create Git repo policies: pull request approver, comment, build.

Example
``` PowerShell
# configure approver, comment, and build repo policies (build policy requires an existing build definition) 
. .\Add-GitRepoBranchPolicyApprover.ps1
Add-GitRepoBranchPolicyApprover -repositoryId $repo.id -minimumApproverCount 2 -context $context
. .\Add-GitRepoBranchPolicyComment.ps1
Add-GitRepoBranchPolicyComment -repositoryId $repo.id -context $context
. .\Add-GitRepoBranchPolicyBuild.ps1
$buildDefId = 0 # get the definition ID for your build
Add-GitRepoBranchPolicyBuild -repositoryId $repo.id -buildDefId $buildDefId -context $context
```

### Add-GitRepoBranch
Create a repo branch, in a folder.

Example
``` PowerShell
# create a repo folder branch (features, releases, users, etc.)
. .\Add-GitRepoBranch.ps1
$folderName = 'features' # 'features' # 'releases'
$branchName = 'F1' # 'F1' # 'R1'
$srcDir = "C:\Sources\ACC-003"
Add-GitRepoBranch -repoName $repoName -srcDir $srcDir -folderName $folderName -branchName $branchName -context $context
```

### Add-GitRepoBranchPermissions
Add branch folder permissions, as per this recommendation: https://docs.microsoft.com/en-us/azure/devops/repos/git/require-branch-folders?view=azure-devops&tabs=browser

Uses the `tf` tool. Locate the path for your VS installation to find the tool.

Example
``` PowerShell
# set repo branch permissions 
# see https://docs.microsoft.com/en-us/azure/devops/repos/git/require-branch-folders?view=azure-devops&tabs=browser
. .\Add-GitRepoBranchPermissions.ps1
# use [where /R C:\ tf.exe] in cmd to find tf.exe tool
$tfDirPath = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Preview\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer"
Add-GitRepoBranchPermissions -repoName $repoName -tfDirPath $tfDirPath -context $context 
```

### Set-GitRepoBranchLock
Lock / Unlock a Git repo branch.

Example
``` PowerShell

# lock release branch
. .\Set-GitRepoBranchLock.ps1
$branchName = 'heads/releases/R1' # 'heads/master' # 'heads/releases/R1'
$lock = $true
Set-GitRepoBranchLock -repositoryId $repo.id -branchName $branchName $lock -context $context
```

### Get-PullRequest
Return a pull request object based on its ID.

Example

``` PowerShell
# get pull request (example)
. .\Get-PullRequest.ps1
$repoName = 'ACC-003-app'
$pullRequestId = 37
$pullRequest = Get-PullRequest -repoName $repoName -pullRequestId $pullRequestId -context $context
$pullRequest | ConvertTo-Json -Depth 10 > "C:\Data\pullrequest.37.json"
```

### Import-PullRequest
Import a pull request based on JSON template. Set the repo name, pull request title and description, and source and target branches. Azure DevOps will identify the changes between branches and will add the commits automatically.
It needs the reviewer ID (added to the list of optional reviewers).
Use the profile API to get your own ID: https://app.vssps.visualstudio.com/_apis/profile/profiles/me?api-version=5.1

Example

``` PowerShell
# create pull request based on JSON template
. .\Import-PullRequest.ps1
$jsonDefFilePath = '.\pullrequest.json'
$repoName = 'ACC-003-app'
$title = 'New pull request 2'
$description = 'Auto-created pull-request'
$sourceBranchName = 'features/F1'
$targetBranchName = 'master'
# use the profile Api to get your own ID: https://app.vssps.visualstudio.com/_apis/profile/profiles/me?api-version=5.1
# for VSTS group, you can use <group>.originId, as returned by Get-Group cmdlet
$reviewerId = '<reviewer ID>' # me
$newPR = Import-PullRequest -jsonDefFilePath $jsonDefFilePath -repoName $repoName -title $title -description $description `
    -sourceBranchName $sourceBranchName -targetBranchName $targetBranchName -reviewerId $reviewerId -context $context `
```

### Get-Project
Return the project object based on its name.

Example

``` PowerShell
# get project object based on name
. .\Get-Project.ps1
$project = Get-Project -projectName $projName -context $context
```

### Import-BuildDef
Import a build definition based on JSON template.
It requires the new definition name, the repo (ID and name), and optionally a task group ID and job authorization scope (`project` or `projectCollection`).

Examples

``` PowerShell

# import a build definition based on JSON template
. .\Import-BuildDef.ps1
$jsonDefFilePath = '..\Pipelines\Templates\template-ASPNETCore-CI.json'
Import-BuildDef -jsonDefFilePath $jsonDefFilePath -projectId $project.id -projectName $projName -buildDefName 'MyBuild-005' -repoId $repo.id -repoName $repo.name -context $context


# import a build definition with MSCA task group based on JSON template
. .\Import-BuildDef.ps1
. .\Get-Project.ps1
. .\Get-GitRepo
$proj = Get-Project -projectName $projName -context $context
$repo = Get-GitRepo -repoName $repoName -context $context
$jsonDefFilePath = '..\Pipelines\Templates\template-BuildWebApp-MSCA-CI.json'
$taskGroupId = '<task group ID>' # get the Task Group ID for the imported ACC-MSCA-001 template; use Get-TaskGroup to retrieve the task group object
$jobAuthorizationScope = 'project'
Import-BuildDef -jsonDefFilePath $jsonDefFilePath -projectId $proj.id -projectName $projName -buildDefName 'ACC-MCSA-003-CI' `
    -repoId $repo.id -repoName $repo.name -taskGroupId $taskGroupId -jobAuthorizationScope $jobAuthorizationScope -context $context

```

### Get-Users
Return the list of users in Azure DevOps organization. If the list is very large, the cmdlet return the first page only.

Example

``` PowerShell
# get users example
. .\Get-Users.ps1
$users = Get-Users -context $context
```

### Import-ReleaseDef
Import a release definition based on JSON template.
It requires the new definition name, the build information (ID and name), project ID, stage owner ID, and approver ID.
The release context requires a different `coreServer` (vsrm.dev.azure.com).

Example

``` PowerShell
# import a release definition based on JSON template (note the release AuthN context for vsrm.dev.azure.com)
# for AAD users originId is not working, you need the profile ID
# use the profile Api to get your own ID: https://app.vssps.visualstudio.com/_apis/profile/profiles/me?api-version=5.1
. .\Get-User.ps1
$userName = 'x@y.com'
$user = Get-User -userName $userName -context $context
$releaseCtx = Get-AzureDevOpsContext -protocol https -coreServer vsrm.dev.azure.com -org $org -project $projName -apiVersion 5.1 `
    -pat $pat -isOnline
. .\Import-ReleaseDef.ps1
$jsonDefFilePath = '..\Pipelines\Templates\template-ASPNETCore-CD.json'
$buildDefId = 62 # your build definition ID
Import-ReleaseDef -jsonDefFilePath $jsonDefFilePath -releaseDefName 'MyRelease-005' -projectId $project.id -buildDefId $buildDefId -buildDefName 'MyBuild-005' -ownerId $user.originId -approverId $user.originId -context $releaseCtx



# import a release definition based on JSON template (note the release AuthN context for vsrm.dev.azure.com)
. .\Get-Group.ps1
$groupName = 'Change Manager'
$group = Get-Group -projectName $projName -groupName $groupName -context $context
$releaseCtx = Get-AzureDevOpsContext -protocol https -coreServer vsrm.dev.azure.com -org $org -project $projName -apiVersion 5.1 `
    -pat $pat -isOnline
. .\Import-ReleaseDef.ps1
$jsonDefFilePath = '..\Pipelines\Templates\template-ASPNETCore-stages-CD.json'
$buildDefId = 62 # your build definition ID
$buildDefName = 'MyBuild-005'
$releaseDefName = 'MyRelease-005-3'
# use the profile Api to get your own ID: https://app.vssps.visualstudio.com/_apis/profile/profiles/me?api-version=5.1
# for VSTS group, you can use <group>.originId, as returned by Get-Group cmdlet
$ownerId = '<profile id>' # me
$approverId = $group.originId
Import-ReleaseDef -jsonDefFilePath $jsonDefFilePath -releaseDefName $releaseDefName -projectId $project.id `
    -buildDefId $buildDefId -buildDefName $buildDefName -ownerId $ownerId -approverId $approverId `
    -context $releaseCtx


```

### Import-TaskGroup
Import a task group based on JSON template.
It requires the new task group name.

Examples

``` PowerShell
# import a task group based on JSON template
. .\Import-TaskGroup.ps1
$jsonDefFilePath = '..\Pipelines\Templates\template-BuildWebApp-taskgroup.json'
$taskGroupName = 'TaskGroup-010'
$taskGroup = Import-TaskGroup -jsonDefFilePath $jsonDefFilePath -taskGroupName $taskGroupName -context $context



# import a task group with MSCA based on JSON template
. .\Import-TaskGroup.ps1
$jsonDefFilePath = '..\Pipelines\Templates\template-BuildWebApp-MSCA-taskgroup.json'
$taskGroupName = 'ACC-MSCA-002'
$taskGroup = Import-TaskGroup -jsonDefFilePath $jsonDefFilePath -taskGroupName $taskGroupName -context $context

```

### Get-Feeds
Return the list of artifact feeds at project or organization level

Example

``` PowerShell
# create feed AuthN context (note the coreServer feeds.dev.azure.com)
$feedCtx = Get-AzureDevOpsContext -protocol https -coreServer feeds.dev.azure.com -org $org -project $projName -apiVersion 5.1 `
    -pat $pat -isOnline

# get feeds example (omit orgLevel switch for project level feeds)
. .\Get-Feeds.ps1
$feeds = Get-Feeds -orgLevel -context $feedCtx 
```

### Get-Feed
Return a feed object based on its name (organization or project level).

Example

``` PowerShell
# get feed by name or id example (omit orgLevel switch for project level feed)
. .\Get-Feed.ps1
$feedName = 'TestDevOps-Feed'
$feed = Get-Feed -feedId $feedName -orgLevel -context $feedCtx 
```

### Add-Feed
Create an artifact feed at organization or project level. It includes options to create public upstream sources (nuget, npm, Maven), or to add all upstream sources from an internal feed. The internal feed can also be at organization or project level.

Example

``` PowerShell
# create artefacts feed - can be at project or org level; use addPublicUpstreamSources switch for public sources such as npm, nuget, or Maven;
# use addInternalUpstreamSource for adding upstream sources from an internal feed
# Get my profile info (use in browser)
# https://app.vssps.visualstudio.com/_apis/profile/profiles/me?api-version=5.1
# Get member orgs (use in browser)
# https://app.vssps.visualstudio.com/_apis/accounts?memberId={memberId}&api-version=5.1

. .\Add-Feed.ps1
$feedName = 'ACC-007'
$feedDescription = 'Simple feed with internal upstream sources'
$internalFeedId = 'TestDevOps-Feed'
$orgId = '<org ID>'
$feed = Add-Feed -name $feedName -description $feedDescription -addInternalUpstreamSource -internalFeedId $internalFeedId -orgLevelInternal `
    $orgId $orgId -context $feedCtx
```

### Set-FeedRetentionPolicy
Set the retention policy for a feed: 
 - `countLimit ` - Maximum versions to preserve per package and package type.
 - `daysToKeepRecentlyDownloadedPackages` - Number of days to preserve a package version after its latest download.

Example

``` PowerShell
# set feed retention policy
. .\Set-FeedRetentionPolicy.ps1
$feedId = 'ACC-007'
$countLimit = 10
$daysToKeepRecentlyDownloadedPackages = 10
Set-FeedRetentionPolicy -feedId $feedId -countLimit $countLimit -daysToKeepRecentlyDownloadedPackages $daysToKeepRecentlyDownloadedPackages -context $feedCtx
```

### Add-UniversalPackage
Add a package (zip file, binary, any type of file) as Universal Package to the specified feed.
It requires the package name, description, version, and local path; it also requires the feed name (only organization level feeds are working at the moment).
Uses `az artifacts universal` CLI.
See this blog for info on UP: https://devblogs.microsoft.com/devops/universal-packages-bring-large-generic-artifact-management-to-vsts/

Example

``` PowerShell
# add custom universal package
# see this blog for info on UP: https://devblogs.microsoft.com/devops/universal-packages-bring-large-generic-artifact-management-to-vsts/
. .\Add-UniversalPackage.ps1
$packageName = 'myownup-002' # must be one or more lowercase alphanumeric segments separated by a dash, dot or underscore. The package name must be under 256 characters 
$packageDescription = 'Universal package cointaining a dummy zip file.'
$feedName = 'TestDevOps-Feed' # 'ACC-007' # it doesn't seem to work for project level feeds, only for org level feeds
$packagePath = "C:\Data\skus-win10.zip"
$packageVersion = '1.0.0'
Add-UniversalPackage -packageName $packageName -packageDescription $packageDescription -feedId $feedName -packagePath $packagePath -packageVersion $packageVersion -context $context
```

### Get-UniversalPackage
Downloads a package (zip file, binary, any type of file) from the universal package store of a particular feed.
It requires the package name and version, the feed name (only organization level), and the directory path where you want to download the package.

Example

``` PowerShell
# download an universal package
. .\Get-UniversalPackage.ps1
$packageName = 'myownup-002' # must be one or more lowercase alphanumeric segments separated by a dash, dot or underscore. The package name must be under 256 characters 
$feedName = 'TestDevOps-Feed' # 'ACC-007' # it doesn't seem to work for project level feeds, only for org level feeds
$outputPath = "C:\Temp"
$packageVersion = '1.0.0'
Get-UniversalPackage -packageName $packageName -feedId $feedName -outputPath $outputPath -packageVersion $packageVersion -context $context
```

### Get-TaskGroups
Return the list of task groups for an Azure DevOps project.

Example

``` PowerShell
# get task groups example
. .\Get-TaskGroups.ps1
$taskGroups = Get-TaskGroups -context $context
```

### Get-TaskGroup
Return a task group object based on its name.

Example

``` PowerShell
# get task group example
. .\Get-TaskGroup.ps1
$taskGroupName = 'ACC-MSCA-002'
$taskGroup = Get-TaskGroup -taskGroupName $taskGroupName -context $context
```

### Set-BuildDefProperty
Set a custom property on a build definition.

Example

``` PowerShell
# set a build definition property - NOT WORKING (it sets a properties container, not exactly properties on the definition itself)
. .\Set-BuildDefProperty.ps1
$buildDefId = 61 # 'MyBuild-002' change to your own Definition ID
$op = 'add' # "add", "remove", "replace"
$propertyPath = '/jobAuthorizationScope' # '/name' # must start with a /
$propertyValue = 0 # 'ACC-MyBuild-002'
Set-BuildDefProperty -buildDefId $buildDefId -op $op -propertyPath $propertyPath -propertyValue $propertyValue -context $context
```

### Get-BuildDefProperties
Return a list of custom properties for a build definition.

Example

``` PowerShell
# get build definition properties example
. .\Get-BuildDefProperties.ps1
$buildDefId = 61
$buildDefProps = Get-BuildDefProperties -buildDefId $buildDefId -context $context
```


### Get-BuildDef
Return a build definition object based on its ID.

Example

``` PowerShell
# get build definition example
. .\Get-BuildDef.ps1
$buildDefId = 64
$buildDef = Get-BuildDef -buildDefId $buildDefId -context $context
```


### Add-YamlPipeline
Create a YAML pipeline based on an existing file stored in a Git repository.
It requires the pipeline name, description, the repo name and the YAML file relative path (relative to the repo root).
Uses `az pipelines` CLI.

Example

``` PowerShell
# create a YAML Pipeline
. .\Add-YamlPipeline.ps1
$name = 'ACC-BuildWeb-App-yml-002'
$description = 'Build ASP.NET Core web app using YAML'
$repoName = 'ACC-003-app'
$yamlPath = 'Pipelines/build-web-app.yml'
Add-YamlPipeline -name $name -description $description -repoName $repoName -yamlPath $yamlPath -context $context
```
