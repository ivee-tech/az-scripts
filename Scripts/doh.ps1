# Remove-Module AzureDevOps
# Import-Module .\AzureDevOps.psm1

$srcSvr = '<tfs server>:8080/tfs';
$srcOrg = '<src collection>';
$srcProjName = '<src project>';
$srcPat = '***'

$destSvr = 'dev.azure.com'
$destOrg = '<dest org>'
$destProjName = '<dest project>'
$destPat = '***'


# $apiVersion = '' # '5.1' for Azure DevOps Services | '5.0' for Azure DevOps Server | '4.1' fro TFS 2018 

$srcCtx = Get-AzureDevOpsContext -protocol https -coreServer $srcSvr -org $srcOrg -project $srcProjName -apiVersion 5.1 `
    -pat $srcPat -isOnline

$relSrcSvr = 'vsrm.dev.azure.com'
$relSrcCtx = Get-AzureDevOpsContext -protocol https -coreServer $relSrcSvr -org $srcOrg -project $srcProjName -apiVersion 5.1 `
    -pat $srcPat -isOnline

$destCtx = Get-AzureDevOpsContext -protocol https -coreServer $destSvr -org $destOrg -project $destProjName -apiVersion 6.0 `
    -pat $destPat -isOnline


# get target project on the destination org
$destProj = Get-Project -projectName $destProjName -context $destCtx
$srcProjDir = "C:\Data\DoH\$($srcProjName)"
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
        if($_.inputs.PSobject.Properties.name -match 'ConnectedServiceName') {
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



# get release definitions
$releaseDefs = Get-ReleaseDefs -context $relSrcCtx
