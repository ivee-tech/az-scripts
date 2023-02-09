# . .\AzureDevOpsContext.ps1

Remove-Module AzureDevOps

Import-Module .\AzureDevOps.psm1

$org = 'daradu'
$projName = 'dawr-demo'
$repoName = "infrastructure"
$pat = '***'

# create an Azure DevOps context for AuthN
# . .\Get-AzureDevOpsContext.ps1
$context = Get-AzureDevOpsContext -protocol https -coreServer dev.azure.com -org $org -project $projName -apiVersion 6.0 `
    -pat $pat -isOnline

# get the list of processes; identify the Agile process ID and use it in the project creation step
# . .\Get-Processes.ps1
$processes = Get-Processes -context $context
$processes.value | ForEach-Object { Write-Host $_.id $_.name }

# create an Azure DevOps project based on the Agile process ID
. .\Add-Project.ps1
$projDescription = 'This project is for product 003.'
$processTemplateId = '***' # Agile
$project = Add-Project -name $projName -description $projDescription -processTemplateId $processTemplateId -context $context

# create a Azure DevOps project team
. .\Add-Team.ps1
$teamName = 'Omega' #'Alpha' # 'Omega'
$team = Add-Team -name $teamName -description $teamName -context $context
$team

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

# set the GenericContribute permission (allow or deny) on Git Repositories (project level) for the required groups
# check security-namespaces.json file for the list of namespaces 
# check security-gitrepos-actions.json for the list of actions for Git Repositores namespace
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

# get project descriptor example
. .\Get-ProjectDescriptor.ps1
$descriptor = Get-ProjectDescriptor -projectName $projName -context $context

# get group list example
. .\Get-Groups.ps1
$groups = Get-Groups -projectName $projName -context $context

# get group example
. .\Get-Group.ps1
$groupName = 'Alpha'
$group = Get-Group -projectName $projName -groupName $groupName -context $context

# set group membership (add one group as member of another group)
. .\Set-GroupMembership.ps1
$groupName = 'Omega' # 'Alpha' # 'Omega'
$containerName = 'Contributors'
Set-GroupMembership -projectName $projName -groupName $groupName -containerName $containerName -context $context

# add Area Paths (not required)
. .\Add-ClassificationNodes.ps1
$response = Add-ClassificationNodes -structureGroup 'areas' -jsonFilePath '.\areas.json' -context $context
$response

# add Iterations (not required)
$response = Add-ClassificationNodes -structureGroup 'iterations' -jsonFilePath '.\iterations.json' -context $context
$response

# create empty Git repository
. .\Add-GitRepo.ps1
$repo = Add-GitRepo -repoName $repoName -context $context

# add repo structure based on ASP.NET Core WebApp template
. .\Add-AspNetCoreGitRepoStructure.ps1
$appName = 'WebApp3'
$srcDir = 'C:\Sources\ACC-003\master'
Add-AspNetCoreGitRepoStructure -repoName $repoName -appName $appName -srcDir $srcDir -context $context

# get list of policy types example
. .\Get-RepoPolicyTypes.ps1
$policyTypes = Get-RepoPolicyTypes -context $context
$policyTypes | ConvertTo-Json -Depth 10 > "C:\Sources\ACC\Scripts\policyTypes.json"

# get repo example
. .\Get-GitRepo
$repo = Get-GitRepo -repoName $repoName -context $context

# configure approver, comment, and build repo policies (build policy requires an existing build definition) 
. .\Add-GitRepoBranchPolicyApprover.ps1
Add-GitRepoBranchPolicyApprover -repositoryId $repo.id -minimumApproverCount 2 -context $context
. .\Add-GitRepoBranchPolicyComment.ps1
Add-GitRepoBranchPolicyComment -repositoryId $repo.id -context $context
. .\Add-GitRepoBranchPolicyBuild.ps1
$buildDefId = 0 # get the definition ID for your build
Add-GitRepoBranchPolicyBuild -repositoryId $repo.id -buildDefId $buildDefId -context $context

# create a repo folder branch (features, releases, users, etc.)
. .\Add-GitRepoBranch.ps1
$folderName = 'features' # 'features' # 'releases'
$branchName = 'F1' # 'F1' # 'R1'
$srcDir = "C:\Sources\ACC-003"
Add-GitRepoBranch -repoName $repoName -srcDir $srcDir -folderName $folderName -branchName $branchName -context $context

# set repo branch permissions 
# see https://docs.microsoft.com/en-us/azure/devops/repos/git/require-branch-folders?view=azure-devops&tabs=browser
. .\Add-GitRepoBranchPermissions.ps1
# use [where /R C:\ tf.exe] in cmd to find tf.exe tool
$tfDirPath = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Preview\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer"
Add-GitRepoBranchPermissions -repoName $repoName -tfDirPath $tfDirPath -context $context 

# lock release branhc
. .\Set-GitRepoBranchLock.ps1
$branchName = 'heads/releases/R1' # 'heads/master' # 'heads/releases/R1'
$lock = $true
Set-GitRepoBranchLock -repositoryId $repo.id -branchName $branchName $lock -context $context

# get pull request (example)
. .\Get-PullRequest.ps1
$repoName = 'ACC-003-app'
$pullRequestId = 37
$pullRequest = Get-PullRequest -repoName $repoName -pullRequestId $pullRequestId -context $context
$pullRequest | ConvertTo-Json -Depth 10 > "C:\Data\pullrequest.37.json"

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

# get project object based on name
. .\Get-Project.ps1
$project = Get-Project -projectName $projName -context $context

# import a build definition based on JSON template
. .\Import-BuildDef.ps1
$jsonDefFilePath = '..\Pipelines\Templates\template-ASPNETCore-CI.json'
Import-BuildDef -jsonDefFilePath $jsonDefFilePath -projectId $project.id -projectName $projName -buildDefName 'MyBuild-005' -repoId $repo.id -repoName $repo.name -context $context

# get users example
. .\Get-Users.ps1
$users = Get-Users -context $context

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
Import-ReleaseDef -jsonDefFilePath $jsonDefFilePath -releaseDefName 'MyRelease-005' -projectId $project.id -buildDefId $buildDefId -buildDefName 'MyBuild-005' -ownerId $user.originId -context $releaseCtx

# import a task group based on JSON template
. .\Import-TaskGroup.ps1
$jsonDefFilePath = '..\Pipelines\Templates\template-BuildWebApp-taskgroup.json'
$taskGroupName = 'TaskGroup-010'
$taskGroup = Import-TaskGroup -jsonDefFilePath $jsonDefFilePath -taskGroupName $taskGroupName -context $context

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

# create feed AuthN context (note the coreServer feeds.dev.azure.com)
$feedCtx = Get-AzureDevOpsContext -protocol https -coreServer feeds.dev.azure.com -org $org -project $projName -apiVersion 5.1 `
    -pat $pat -isOnline

# get feeds example (omit orgLevel switch for project level feeds)
. .\Get-Feeds.ps1
$feeds = Get-Feeds -orgLevel -context $feedCtx 


# get feed by name or id example (omit orgLevel switch for project level feed)
. .\Get-Feed.ps1
$feedName = 'TestDevOps-Feed'
$feed = Get-Feed -feedId $feedName -orgLevel -context $feedCtx 


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

# set feed retention policy
. .\Set-FeedRetentionPolicy.ps1
$feedId = 'ACC-007'
$countLimit = 10
$daysToKeepRecentlyDownloadedPackages = 10
Set-FeedRetentionPolicy -feedId $feedId -countLimit $countLimit -daysToKeepRecentlyDownloadedPackages $daysToKeepRecentlyDownloadedPackages -context $feedCtx





# add custom universal package
# see this blog for info on UP: https://devblogs.microsoft.com/devops/universal-packages-bring-large-generic-artifact-management-to-vsts/
. .\Add-UniversalPackage.ps1
$packageName = 'myownup-002' # must be one or more lowercase alphanumeric segments separated by a dash, dot or underscore. The package name must be under 256 characters 
$packageDescription = 'Universal package cointaining a dummy zip file.'
$feedName = 'TestDevOps-Feed' # 'ACC-007' # it doesn't seem to work for project level feeds, only for org level feeds
$packagePath = "C:\Data\skus-win10.zip"
$packageVersion = '1.0.0'
Add-UniversalPackage -packageName $packageName -packageDescription $packageDescription -feedId $feedName -packagePath $packagePath -packageVersion $packageVersion -context $context

# download an universal package
. .\Get-UniversalPackage.ps1
$packageName = 'myownup-002' # must be one or more lowercase alphanumeric segments separated by a dash, dot or underscore. The package name must be under 256 characters 
$feedName = 'TestDevOps-Feed' # 'ACC-007' # it doesn't seem to work for project level feeds, only for org level feeds
$outputPath = "C:\Temp"
$packageVersion = '1.0.0'
Get-UniversalPackage -packageName $packageName -feedId $feedName -outputPath $outputPath -packageVersion $packageVersion -context $context


# import a task group with MSCA based on JSON template
. .\Import-TaskGroup.ps1
$jsonDefFilePath = '..\Pipelines\Templates\template-BuildWebApp-MSCA-taskgroup.json'
$taskGroupName = 'ACC-MSCA-002'
$taskGroup = Import-TaskGroup -jsonDefFilePath $jsonDefFilePath -taskGroupName $taskGroupName -context $context

# get task groups example
. .\Get-TaskGroups.ps1
$taskGroups = Get-TaskGroups -context $context

# get task group example
. .\Get-TaskGroup.ps1
$taskGroupName = 'ACC-MSCA-002'
$taskGroup = Get-TaskGroup -taskGroupName $taskGroupName -context $context

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

# set a build definition property - NOT WORKING (it sets a properties container, not exactly properties on the definition itself)
. .\Set-BuildDefProperty.ps1
$buildDefId = 61 # 'MyBuild-002' change to your own Definition ID
$op = 'add' # "add", "remove", "replace"
$propertyPath = '/jobAuthorizationScope' # '/name' # must start with a /
$propertyValue = 0 # 'ACC-MyBuild-002'
Set-BuildDefProperty -buildDefId $buildDefId -op $op -propertyPath $propertyPath -propertyValue $propertyValue -context $context

# get build definition example
. .\Get-BuildDef.ps1
$buildDefId = 64
$buildDef = Get-BuildDef -buildDefId $buildDefId -context $context

# get build definition properties example
. .\Get-BuildDefProperties.ps1
$buildDefId = 61
$buildDefProps = Get-BuildDefProperties -buildDefId $buildDefId -context $context


# create a YAML Pipeline
. .\Add-YamlPipeline.ps1
$name = 'ACC-BuildWeb-App-yml-002'
$description = 'Build ASP.NET Core web app using YAML'
$repoName = 'ACC-003-app'
$yamlPath = 'Pipelines/build-web-app.yml'
Add-YamlPipeline -name $name -description $description -repoName $repoName -yamlPath $yamlPath -context $context


# Get group using az devops CLI
. .\Get-GroupAzDevOpsCli.ps1
$groupName = 'Project Administrators'
$group = Get-GroupAzDevOpsCli -projectName $context.project -groupName $groupName -context $context
$group.GetType()
$group.descriptor


# Get group membership
. .\Get-GroupMembership.ps1
$groupName = 'Project Valid Users'
$members = (Get-GroupMembership -projectName $projName -groupName $groupName -context $context) | ConvertFrom-Json
$members.PSObject.Properties| ForEach-Object { $_.Value.displayName }

# Get the project admins group membership
. .\Get-Projects.ps1
. .\Get-GroupAzDevOpsCli.ps1
. .\Get-GroupMembership.ps1
$projects = Get-Projects -context $context
$groupName = 'Project Administrators'
$projects | ForEach-Object {
    # $group = Get-GroupAzDevOpsCli -projectName $_.name -groupName $groupName -context $context
    Write-Host $group.displayName $group.descriptor "Membership:"
    $members = (Get-GroupMembership -projectName $_.name -groupName $group.displayName -context $context) | ConvertFrom-Json
    $members.PSObject.Properties| ForEach-Object { Write-Host "  " $_.Value.displayName }
}

# Get all project admins in a group
. .\Get-OrgGroupMembership.ps1
$groupName = 'Project Administrators'
$orgGroupMembers = Get-OrgGroupMembership -groupName $groupName -context $context
$orgGroupMembers | ForEach-Object {
    Write-Host "Membership for group $($_.groupName)"
    $_.members | ForEach-Object { Write-Host "  " $_.displayName }
}




# import a task group based on JSON template
. .\Import-TaskGroup.ps1
$taskGroupName = 'ESS.TG.Template'
$jsonDefFilePath = "C:\Data\ESG\$taskGroupName.json"
$taskGroup = Import-TaskGroup -jsonDefFilePath $jsonDefFilePath -taskGroupName $taskGroupName -context $context


# import Process Template
. .\Import-ProcessTemplate.ps1
$zipFilePath = "C:\Data\ESG\ReleaseLogs_54.zip"
$result = Import-ProcessTemplate -zipFilePath $zipFilePath -context $context
$result


$upn = 'a@a.com'
$accountLicenseType = 'professional'
$response = Add-UserProjectEntitlement -upn $upn -accountLicenseType $accountLicenseType -projectId $null -context $context
$response


# Add binary file to Universal Package
$packageName = 'dotnet-sdk-3.1.109-win-x64'
$packageDescription = '.NET Core SDK v3.1.109-win-x64'
$feedId = 'daradu-feed-001'
$packagePath = "C:\Kit\VS\dotnet-sdk-3.1.109-win-x64.exe"
$packageVersion = "3.1.109"
Add-UniversalPackage -packageName $packageName -packageDescription $packageDescription -feedId $feedId -packagePath $packagePath -packageVersion $packageVersion -context $context

# Get binary file from Universal Package
$packageName = 'dotnet-sdk-3.1.109-win-x64'
$feedId = 'daradu-feed-001'
$outputPath = "C:\Temp"
$packageVersion = "3.1.109"
Get-UniversalPackage -packageName $packageName -feedId $feedId -outputPath $outputPath -packageVersion $packageVersion -context $context


# Add binary file to Universal Package
$packageName = 'dotnet-sdk-3.1.403-win-x64'
$packageDescription = '.NET Core SDK v3.1.403-win-x64'
$feedId = 'daradu-feed-001'
$packagePath = "C:\Kit\VS\dotnet-sdk-3.1.403-win-x64.exe"
$packageVersion = "3.1.403"
Add-UniversalPackage -packageName $packageName -packageDescription $packageDescription -feedId $feedId -packagePath $packagePath -packageVersion $packageVersion -context $context

# Get binary file from Universal Package
$packageName = 'dotnet-sdk-3.1.403-win-x64'
$feedId = 'daradu-feed-001'
$outputPath = "C:\Temp"
$packageVersion = "3.1.403"
Get-UniversalPackage -packageName $packageName -feedId $feedId -outputPath $outputPath -packageVersion $packageVersion -context $context

<#
Remove-Module AzureDevOps
Import-Module ..\AzureDevOps.psm1
.\psDoc.ps1 -moduleName AzureDevOps -template './out-markdown-template.ps1'
Get-Help Get-Projects -Examples
#>

# Invoke-CreateModuleHelpFile -ModuleName AzureDevOps -Path 'C:\Data\help.html'

# Install-Module -Name platyPS

Import-Module platyPS
Import-Module AzureDevOps
New-MarkdownHelp -Module AzureDevOps -OutputFolder .\docs




# Backup Git Repo
$repoName = "infrastructure"
$backupsPath = 'C:\Users\daradu\source\repos\backup'
$result = Backup-GitRepo -backupsPath $backupsPath -repoName $repoName -archive -context $context

. .\Azure\Get-StorageAccountSAS.ps1
$rgName = 'DAResourceGroup'
$acctName = 'dastorageacc'
$containerName = 'azuredevops-backups'
$sasToken = Get-StorageAccountSAS -rgName $rgName -acctName $acctName -containerName $containerName -hoursValidity 0.5
$sasToken

. .\Azure\Copy-FileToStorageAccount.ps1
$filePath = $result.zipFilePath # "C:\Users\daradu\source\repos\backup\daradu\dawr-demo\infrastructure\20201022_0930\20201022_0930.zip"
$fileName = "daradu/dawr-demo/infrastructure/$($result.zipFileName)"
Copy-FileToStorageAccount -acctName $acctName -sasToken $sasToken -containerName $containerName -filePath $filePath -fileName $fileName


$part = "20201022_1300"
. .\Azure\Copy-FileFromStorageAccount.ps1
$filePath = "C:\Users\daradu\source\repos\restore\daradu\dawr-demo\infrastructure\$part"
$fileName = "daradu/dawr-demo/infrastructure/$part.zip"
Copy-FileFromStorageAccount -acctName $acctName -sasToken $sasToken -containerName $containerName -filePath $filePath -fileName $fileName

# Create new Git Repo
$newRepoName = "$repoName.$part"
Add-GitRepo -repoName $newRepoName -context $context

# Restore the backup into the new Git Repo
$repoBackupPath = "C:\Users\daradu\source\repos\restore\daradu\dawr-demo\infrastructure\$part.zip"
$newRepoName = "$repoName.$part"
Restore-GitRepo -repoBackupPath $repoBackupPath -repoName $newRepoName -expand -context $context

