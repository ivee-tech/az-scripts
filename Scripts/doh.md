# Azure DevOps migration - repos and pipelines

The guide below shows how to perform low-fidelity migration for Azure Repos and Azure Pipelines using Azure DevOps REST API and PowerShell.

The code works for migration from Azure DevOps Server (on-prem) to Azure DevOps Services in the cloud, as well as any combination* 

*please note that not all combinations have been tested

> DISCLAIMER:
Due to the large number of possibilities, dependencies, customisations and setup, a fully successful migration cannot be guaranteed. 

> This is a best-effort approach ensuring most of the data is migrated from the source to the destination. Testing post-migration is crucial and could require multiple migration attempts.

> In order to identify potential migration issues, it is highly advised to perform a sufficient number of dry-run migrations, including partial migrations. For example, if you have a complex pipeline that fails during a dry-run migration, it is a good idea to focus on that particular migration to fix all the problems.

# AzureDevOps Module
The scripts are organised in PowerShell cmdlets which perform various tasks, based on Azure DevOps REST API endpoints.

The cmdlets are stored in the *Scripts/AzureDevOps* directory and the module is under *Scripts/AzureDevOps.psm1* file.

The module file must be generated whenever there are cmdlets changes. Check the script *Scripts/build-azure-devops-module.ps1*.

Below is an example on how the module is generated, with optional removal / import from / into memory:

``` PS
$funcFiles = '.\AzureDevOps\*.ps1'
$moduleName = 'AzureDevOps'
$modulePath = ".\$moduleName.psm1"

Get-Content -Path $funcFiles | Set-Content -Path $modulePath

# optionally, import module
Remove-Module AzureDevOps
Import-Module $modulePath -Verbose

```

# AzurDevOps cmdlets

`AzureDevOps` cmdlets are PowerShell functions which receive parameters and call APIs passing the required data to a specific Azure DevOps REST API endpoint.

The general naming convention name for PowerShell cmdlets is

```
<verb>-<noun>
```

where `verb` can be `Get`, `Add`, `Remove` and noun indicates the DevOps target item, e.g. `GitRepo`, `BuildDef`, `TaskGroup`, etc.

Most of the cmdlets receive a `context` parameter which contains authentication information.

For simplicity, authentication is performed using `PAT`. When generating PATs, ensure they need the appropriate scope to ensure the action performed is successful (Read, Write, Manage etc.)


# Authentication context

This is a simple PowerShell object which contains authentication information for a TFS / Azure DevOps Server collection / project or Azure DevOps Services organisation.

``` PS
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
```

The object is created using the `Get-AzureDevOpsContext` cmdlet, which receives Url elements and optionally a PAT and derives the organisation / project Urls and the BASE64 PAT encoding.

``` PS
$svr = 'dev.azure.com';
$org = 'myorg';
$projName = 'myproj';
$pat = '***'

$ctx = Get-AzureDevOpsContext -protocol https -coreServer $svr -org $org -project $projName -apiVersion 5.1 `
    -pat $srcPat -isOnline
```

The `isOnline` switch is used to differentiate between TFS / Azure DevOps Server on-prem (if not used) and Azure DevOps Services in the cloud (if used).

## Cmdlet example

The cmdlet name indicates the action and the DevOps target item. Actions are based on REST API verbs, such as `GET`, `POST`, `DELETE`, etc.

For example, `Get-GitRepo` cmdlet returns an object of type `PSCustomObject` containg git repository information for a specific repository name.

``` PS
$gitRepoUrl = $context.projectBaseUrl + '/git/repositories/' + $repoName + '?api-version=' + $context.apiVersion
Write-Host $gitRepoUrl
if($context.isOnline) {
    $repo = Invoke-WebRequest -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $gitRepoUrl -Method Get -UseBasicParsing
}
else {
    $repo = Invoke-WebRequest -Uri $gitRepoUrl -UseDefaultCredentials -Method Get -UseBasicParsing
}
return $repo.Content | ConvertFrom-Json

```

Here is an usage example:

``` PS
# create an auth context $ctx
$ctx = Get-AzureDevOpsContext -protocol https -coreServer $svr -org $org -project $projName -apiVersion 5.1 `
    -pat $srcPat -isOnline

# get the repo
$repoName = 'myrepo'
$repo = Get-GitRepo -repoName $repoName -context $ctx
```

# Migration

The script located in *Scripts/doh.ps1* file contains the entry point execution for script migration.

Fully executing the script is NOT recommended, as it is highly unlikely the migration will work from the first attempt.

Instead, focus on migration slices, such as GIT repos, TFVC, build definitions, release definitions etc.

## WIP

$srcSvr = '<tfs server>:8080/tfs';
$srcOrg = '<src collection>';
$srcProjName = '<src project>';
$srcPat = '***'

$destSvr = 'dev.azure.com'
$destOrg = '<dest org>'
$destProjName = '<dest project>'
$destPat = '***'


# $apiVersion = '' # '5.1' for Azure DevOps Services | '5.0' for Azure DevOps Server | '4.1' fro TFS 2018 
$codeRootDir = "C:\s\DoH"
$dataRootDir = "C:\Data\DoH"

$srcCtx = Get-AzureDevOpsContext -protocol https -coreServer $srcSvr -org $srcOrg -project $srcProjName -apiVersion 5.1 `
    -pat $srcPat -isOnline
$relSrcSvr = 'vsrm.dev.azure.com'
$relSrcCtx = Get-AzureDevOpsContext -protocol https -coreServer $relSrcSvr -org $srcOrg -project $srcProjName -apiVersion 5.1 `
    -pat $srcPat -isOnline

$destCtx = Get-AzureDevOpsContext -protocol https -coreServer $destSvr -org $destOrg -project $destProjName -apiVersion 6.0 `
    -pat $destPat -isOnline
$relDestSvr = 'vsrm.dev.azure.com'
$relDestCtx = Get-AzureDevOpsContext -protocol https -coreServer $relDestSvr -org $destOrg -project $destProjName -apiVersion 6.0 `
        -pat $destPat -isOnline
    

# get target project on the destination org
$destProj = Get-Project -projectName $destProjName -context $destCtx
$srcProjDir = "$dataRootDir\$($srcProjName)"
New-Item -Path $srcProjDir -ItemType Directory -ErrorAction SilentlyContinue

# remove all dest GIT repos
<#
$destRepos = Get-GitRepos -context $destCtx
$destRepos.value | ForEach-Object {
    if($destProjName -ne $_.name) { # keep default repo
        Remove-GitRepo -repoId $_.id -context $destCtx
    }
}
#>
# get all GIT repositories
$repos = Get-GitRepos -context $srcCtx

# migrate GIT repositories
$reposDir = "$($srcProjDir)\repos"
New-Item -Path $reposDir -ItemType Directory -ErrorAction SilentlyContinue
# $repos | ConvertTo-Json -Depth 10 | Out-File $reposDir\repos.json
$currentLocation = Get-Location
$repos.value | Where-Object { -not($_.isDisabled) } | ForEach-Object {

$repoName = $_.name
Set-Location $reposDir
git -c http.extraHeader="Authorization: Basic $($srcCtx.base64AuthInfo)" clone --mirror https://dev.azure.com/$($srcCtx.org)/$($srcCtx.project)/_git/$($repoName)
$repo = Add-GitRepo -repoName $repoName -context $destCtx
Set-Location $reposDir/$($repoName).git
git remote rm origin
git remote add origin $repo.remoteUrl
git -c http.extraHeader="Authorization: Basic $($destCtx.base64AuthInfo)" push origin --mirror

}
Set-Location $currentLocation


# TFVC

$srcWorkspace = 'daradu' # src collection
$destWorkspace = 'ZipZappAus' # dest org
$srcWorkspaceDir = "$codeRootDir\$($srcWorkspace)"
$destWorkspaceDir = "$codeRootDir\$($destWorkspace)"
$srcTfvcProjDir = "$srcWorkspaceDir\$($srcCtx.project)"
$destTfvcProjDir = "$destWorkspaceDir\$($destCtx.project)"
# dir /s tf.exe to find the location of tf tool (similar to the path below)
$tfPath = "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\tf.exe"

# one-off execution to create the source and destinatino workspaces
# map the $srcWorkspaceDir and $destWorkspaceDir in the dialog
tf workspace $srcWorkspace /new /collection:$($srcCtx.orgUrl)
tf workspace $destWorkspace /new /collection:$($destCtx.orgUrl)
New-Item -Path $srcWorkspaceDir -ItemType Directory -ErrorAction SilentlyContinue
New-Item -Path $destWorkspaceDir -ItemType Directory -ErrorAction SilentlyContinue

$currentLocation = Get-Location
Set-Location $srcWorkspaceDir
& $tfPath get
Set-Location $destWorkspaceDir
& $tfPath get
Copy-Item -Path "$srcTfvcProjDir\*" -Destination $destTfvcProjDir -Recurse -Force
& $tfPath add
& $tfPath checkin /comment:"Added files from source $($srcCtx.projectUrl)" /recursive /noprompt
Set-Location $currentLocation


# PRs migration



# get task groups
$taskGroups = Get-TaskGroups -context $srcCtx
$taskGroupsDir = "$($srcProjDir)\taskGroups"
New-Item -Path $taskGroupsDir -ItemType Directory -ErrorAction SilentlyContinue

# migrate task groups
$taskGroups.value | ForEach-Object {
    $taskGroup = $_
    $taskGroup | ConvertTo-Json -Depth 10 | Out-File "$($taskGroupsDir)\$($taskGroup.name).json"
    Set-TaskGroup -taskGroup $taskGroup -srcTaskGroups $taskGroups.value -destCtx $destCtx
}

# remove all dest build definitions
<#
$destBuildDefs = Get-BuildDefs -context $destCtx
$destBuildDefs.value | ForEach-Object {
    Remove-BuildDef -buildDefId $_.id -context $destCtx
}
#>
# get all build definitions
$buildDefs = Get-BuildDefs -context $srcCtx

# get all pipelines - not required, build definitions should be OK
# $pipelines = Get-Pipelines -context $srcCtx

# get Azure Pipelines queue for destination project
$queue = Get-QueueByName -queueName 'Azure Pipelines' -context $destCtx 
$taskGroups = Get-TaskGroups -context $srcCtx
$destRepos = Get-GitRepos -context $destCtx

$buildDir = "$srcProjDir\build"
New-Item -Path $buildDir -ItemType Directory -ErrorAction SilentlyContinue

$buildDefs.value | ForEach-Object {

$def = Get-BuildDef -buildDefId $_.id -context $srcCtx
$def | ConvertTo-Json -Depth 10 | Out-File "$($buildDir)\$($def.name).json"
$destRepo = $destRepos | Where-Object { $_.repoName -eq $def.repository.name } | Select-Object -First 1
if($null -ne $destRepo) { # only create build definition if repo exists

# resolve variable groups
if($null -ne $def.variableGroups) {
    $varGroupNames = $def.variableGroups | Select-Object -Property "name"
    $def.variableGroups = @()
    $varGroupNames | ForEach-Object {
        $grp = Get-VarGroupByName -varGroupName $_.name -context $destCtx
        if($null -eq $grp) {
            $vars = Get-VarGroupVars -varGroupName $_.name -context $srcCtx
            $grp = Add-VarGroup -varGroupName $_.name -vars $vars -context $destCtx
        }
        $def.variableGroups += @{ id = $grp.id }
    }
}
# resolve task groups
$def.process.phases | ForEach-Object {
    $_.steps | Where-Object { $_.task.definitionType -eq 'metaTask' } | ForEach-Object {
        $step = $_
        $foundTaskGroups = $taskGroups.value | Where-Object { $_.id -eq $step.task.id }
        if($null -ne $foundTaskGroups) {
            $taskGroup = $foundTaskGroups[0]
            $destTaskGroup = Get-TaskGroupByName -taskGroupName $taskGroup.name -context $destCtx
            $step.task.id = $destTaskGroup.id   
        }
    }
}
# resolve service connections - temporarily disable
$def.process.phases | ForEach-Object {
    $_.steps | ForEach-Object {
        if($_.inputs.PSObject.Properties.name -match 'ConnectedServiceName') {
            $_.inputs.ConnectedServiceName = $null
        }
    }
}
# resolve misc dependencies
$def.project.id = $destProj.id
$def.repository.id = $destRepo.id
$def.queue.id = $queue.id
$buildDef = Add-BuildDef -def $def -context $destCtx

} # if $destRepo
} # for each build def

# GIT branch policies
# delete dest branch policies
<#
$destPolicies = Get-RepoPolicies -context $destCtx
$destPolicies.value | ForEach-Object {
    Remove-GitRepoBranchPolicy -policyId $_.id -context $destCtx
}
#>

# get policies
$policies = Get-RepoPolicies -context $srcCtx
$policiesDir = "$($srcProjDir)\policies"
New-Item -Path $policiesDir -ItemType Directory -ErrorAction SilentlyContinue
$policies.value | ConvertTo-Json -Depth 10 | Out-File "$($policiesDir)\policies.json"

$repos = Get-GitRepos -context $srcCtx
$destRepos = Get-GitRepos -context $destCtx
$buildDefs = Get-BuildDefs -context $srcCtx
$destBuildDefs = Get-BuildDefs -context $destCtx

$createPolicy = $true
$policies.value | ForEach-Object {
    $createPolicy = $false
    $policy = $_
    $srcScope = $policy.settings.scope[0] # get src repo info
    $foundRepo = $repos.value | Where-Object { $_.id -eq $srcScope.repositoryId } | Select-Object -First 1
    if($null -ne $foundRepo) {
        $foundDestRepo = $destRepos.value | Where-Object { $_.name -eq $foundRepo.name } | Select-Object -First 1
        $foundDestRepo
        if($null -ne $foundDestRepo) {
            $policy.settings.scope[0].repositoryId = $foundDestRepo.id
            $createPolicy = $true
        }
    }
    if($createPolicy) {
        if($null -ne $policy.settings.buildDefinitionId) {
            $buildDefId = $policy.settings.buildDefinitionId
            $buildDef = $buildDefs.value | Where-Object { $_.id -eq $buildDefId } | Select-Object -First 1
            if($null -ne $buildDef) {
                $destBuildDef = $destBuildDefs.value | Where-Object { $_.name -eq $buildDef.name } | Select-Object -First 1
                if($null -ne $destBuildDef) {
                    $policy.settings.buildDefinitionId = $destBuildDef.id
                }
            }
        }
        $destPolicy = Add-GitRepoBranchPolicy -policy $policy -context $destCtx
    }
}


# Release defintions
# remove all dest release definitions
<#
$destReleaseDefs = Get-ReleaseDefs -context $relDestCtx
$destReleaseDefs.value | ForEach-Object {
    Remove-ReleaseDef -releaseDefId $_.id -context $relDestCtx
}
#>

# get release definitions
$releaseDefs = Get-ReleaseDefs -context $relSrcCtx
$releasesDir = "$($srcProjDir)\release"
New-Item -Path $releasesDir -ItemType Directory -ErrorAction SilentlyContinue

$srcVarGroups = Get-VarGroups -context $srcCtx
$destVarGroups = Get-VarGroups -context $destCtx
$queue = Get-QueueByName -queueName 'Azure Pipelines' -context $destCtx 

# migrate release definitions
$releaseDefs.value | ForEach-Object {
    $releaseDef = Get-ReleaseDef -releaseDefId $_.id -context $relSrcCtx
    $releaseDef | ConvertTo-Json -Depth 10 | Out-File "$releasesDir\$($releaseDef.name).json"
    # resolve variable groups at release def level
    $releaseDef.variableGroups | ForEach-Object {
        $srcVarGroupId = $_.id
        $srcVarGroup = $srcVarGroups.value | Where-Object { $_.id = $srcVarGroupId } | Select-Object -First 1
        if($null -ne $srcVarGroup) {
            $destVarGroup = $destVarGroups.value | Where-Object { $_.name -eq $srcVarGroup.name } | Select-Object -First 1
            if($null -ne $destVarGroup) {
                $destEnvVarGroups += $destVarGroup.id
            }
        }
    }
    $releaseDef.variableGroups = $destEnvVarGroups
    # resolve variable groups at stage level
    $releaseDef.environments | ForEach-Object {
        $env = $_
        $destEnvVarGroups = @()
        $env.variableGroups | ForEach-Object {
            $srcVarGroupId = $_.id
            $srcVarGroup = $srcVarGroups.value | Where-Object { $_.id = $srcVarGroupId } | Select-Object -First 1
            if($null -ne $srcVarGroup) {
                $destVarGroup = $destVarGroups.value | Where-Object { $_.name -eq $srcVarGroup.name } | Select-Object -First 1
                if($null -ne $destVarGroup) {
                    $destEnvVarGroups += $destVarGroup.id
                }
            }
        }
        $env.variableGroups = $destEnvVarGroups
        $env.deployPhases | ForEach-Object {
            $deployPhase = $_
            if($deployPhase.deploymentInput.PSObject.Properties.Name -match "queueId") {
                $deployPhase.deploymentInput.queueId = $queue.id
            }
        }
    }
    $releaseDef.id = $null
    Add-ReleaseDef -def $releaseDef -context $relDestCtx
}
