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

# *********************************************************
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


# *********************************************************
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


# *********************************************************
# PRs migration



# *********************************************************
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

# *********************************************************
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


# *********************************************************
# Release definitions
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





# *********************************************************
# add iterations

# Remove-Module AzureDevOps
# Import-Module .\AzureDevOps.psm1

$svr = 'dev.azure.com';
$org = 'daradu';
$projName = 'dawr-demo';
$pat = '***'
$apiVersion = '7.0'

# $apiVersion = '' # '5.1' for Azure DevOps Services | '5.0' for Azure DevOps Server | '4.1' fro TFS 2018 
$ctx = Get-AzureDevOpsContext -protocol https -coreServer $svr -org $org -project $projName -apiVersion $apiVersion `
    -pat $pat -isOnline

# add iterations based on iterations.json file which defines the entire structure for FY 23-24
$response = Add-ClassificationNodes -structureGroup 'iterations' -jsonFilePath '.\iterations.ac.json' -context $ctx
$response

# add root area path for the team
$areaPath = 'Aged Care Team1' # 'DoH'
$response = Add-ClassificationNode -structureGroup 'areas' -name $areaPath -path '' -context $ctx
$response

# create the team
$teamName = 'Aged Care Team1' # 'DoH'
$team = Add-Team -name $teamName -description $teamName -context $ctx
$team

# configure default area path for the team
$teamName = 'Aged Care Team1' # 'DoH'
$areaPath = "$projName\$teamName"
$team = Set-TeamAreaPath -teamName $teamName -areaPath $areaPath -context $ctx
$team

# configure backlog and default iteration for the team
$teamName = 'Aged Care Team1' # 'DoH'
$iterationPath = "Aged Care Projects" # "$teamName"
$iteration = Get-ClassificationNodeByPath -structureGroup 'iterations' -path $iterationPath -context $ctx
# use iteration identifier, not path
$defaultIteration = $iteration.identifier
$team = Set-TeamSettings -teamName $teamName -backlogIteration $defaultIteration -defaultIteration $defaultIteration -context $ctx
$team


# get main iteration
$iterationPath = "Aged Care Projects\Aged Care PIs" # 'DoH'
$iteration = Get-ClassificationNodeByPath -structureGroup 'iterations' -path $iterationPath -context $ctx

# get all iteration hierarchy as we don't have a way to extract only the desired iterations
$iterations = Get-ClassificationNodes -structureGroup 'iterations' -ids $iteration.id -depth 5 -context $ctx
# get the sprints (by convention, sprints are the "leaf" iterations)
$sprints = Get-LeafClassificationNodes -classificationNode $iterations.value[0]

# get the future sprints based on a date and add them to the team
$d = (Get-Date) # .AddMonths(3)
$futureSprints = $sprints | Where-Object { [DateTime]$_.attributes.startDate -ge $d }
$teamName = 'Aged Care Team1' # 'DoH'
$numberOfSprints = 3
$futureSprints | Sort-Object -Property { [DateTime]$_.attributes.startDate } | Select-Object -First $numberOfSprints | ForEach-Object {
    Set-TeamIteration -teamName $teamName -iterationIdentitifer $_.identifier -context $ctx
}


$svr = 'dev.azure.com';
$org = 'daradu';
$projName = 'dawr-demo';
$pat = '***'
$apiVersion = '7.0'

# $apiVersion = '' # '5.1' for Azure DevOps Services | '5.0' for Azure DevOps Server | '4.1' fro TFS 2018 
$ctx = Get-AzureDevOpsContext -protocol https -coreServer $svr -org $org -project $projName -apiVersion $apiVersion `
    -pat $pat -isOnline


# *********************************************************
# configure board columns
$teamName = 'DoH'
$boardName = 'Stories' # Features, Epics, depending on the Team configuration
$columns = Get-BoardColumns -teamName $teamName -boardName $boardName -context $ctx
$columns.value | ConvertTo-Json -Depth 10 | Out-File 'board-columns.doh.json'

# update columns based on existing configuration; 
# add a new in-progress column called QA, split in Doing / Done, with state ampping for User Story = QA and 7 items limit
<#
name = "QA"
itemLimit =  7
stateMappings = @{
                    "User Story" = "QA"
                }
isSplit =  $true
description = ""
columnType = "inProgress"
#>

$qaColumnId = "96cfa0d1-03a2-4934-ba01-2ac4744667d2" # $null # null for new columns, use existing ID for update
$newBoardColumns = @(
    @{
        id = "63789f9b-2ba8-4643-8e42-d863b4031b73"
        name = "New"
        itemLimit =  0
        stateMappings = @{
                              "User Story" = "New"
                          }
        columnType = "incoming"
    },
    @{
        id = "c4652cc7-47f9-4e25-baff-f23309f92487"
        name = "Active"
        itemLimit =  5
        stateMappings = @{
                              "User Story" = "Active"
                          }
        isSplit =  $false
        description = ""
        columnType = "inProgress"
    },
    @{
        id = "6b13a259-c367-48fe-a38a-0f268730380b"
        name = "Dev"
        itemLimit =  5
        stateMappings = @{
                              "User Story" = "Dev"
                          }
        isSplit =  $false
        description = ""
        columnType = "inProgress"
    },
    @{
        id = "1d647c9e-45ed-408b-9ca6-2e9be9fd428e"
        name = "Test"
        itemLimit =  5
        stateMappings = @{
                              "User Story" = "Test"
                          }
        isSplit =  $false
        description = ""
        columnType = "inProgress"
    },
    @{
        id = "bbc1cfa6-c479-4fea-9658-98684bfd5014"
        name = "Resolved"
        itemLimit =  5
        stateMappings = @{
                              "User Story" = "Resolved"
                          }
        isSplit =  $false
        description = ""
        columnType = "inProgress"
    },
    @{
        id = "9c094c7e-2419-4ffa-aa20-c81df24c5470"
        name = "Prod"
        itemLimit = 5
        stateMappings = @{
                              "User Story" = "Prod"
                          }
        isSplit =  $false
        description = ""
        columnType = "inProgress"
    },
    @{
        id = $qaColumnId
        name = "QA"
        itemLimit =  7
        stateMappings = @{
                              "User Story" = "QA" # "New" # "QA"
                          }
        isSplit =  $true
        description = ""
        columnType = "inProgress"
    },
    @{
        id = "78155db9-7a29-41d4-9201-75160264790f"
        name = "Closed"
        itemLimit = 0
        stateMappings = @{
                              "User Story" = "Closed"
                          }
        columnType = "outgoing"
    }
)
$teamName = 'DoH'
$boardName = 'Stories' # Features, Epics, depending on the Team configuration
$response = Set-BoardColumns -teamName $teamName -boardName $boardName -columns $newBoardColumns -context $ctx
$response

$planId = 1590
$suiteId = 1658
$queryString = "select [System.Id], [System.WorkItemType], [System.Title], [Microsoft.VSTS.Common.Priority], [System.AssignedTo], [System.AreaPath] from WorkItems where [System.TeamProject] = @project and [System.WorkItemType] in group 'Microsoft.TestCaseCategory' and [System.AreaPath] under 'dawr-demo\\Team 1'"
$suite = Set-TestPlanSuite -planId $planId -suiteId $suiteId -queryString $queryString -context $ctx
$suite


# *********************************************************
# tag build run

$svr = 'dev.azure.com';
$org = 'ZipZappAus';
$projName = 'Demos';
$pat = '***'
$apiVersion = '7.0'

# $apiVersion = '' # '5.1' for Azure DevOps Services | '5.0' for Azure DevOps Server | '4.1' fro TFS 2018 
$ctx = Get-AzureDevOpsContext -protocol https -coreServer $svr -org $org -project $projName -apiVersion $apiVersion `
    -pat $pat -isOnline

$buildId = 1216 # kv-infra-envs-build
$tags = @('XYZ')
$result = Add-BuildTags -buildId $buildId -tags $tags -context $ctx
$result

$tag = 'XYZ'
$result = Remove-BuildTag -buildId $buildId -tag $tag -context $ctx
$result



# *********************************************************
# queue build

$svr = 'dev.azure.com';
$org = 'ZipZappAus';
$projName = 'Demos';
$pat = '***'
$apiVersion = '7.0'

# $apiVersion = '' # '5.1' for Azure DevOps Services | '5.0' for Azure DevOps Server | '4.1' fro TFS 2018 
$ctx = Get-AzureDevOpsContext -protocol https -coreServer $svr -org $org -project $projName -apiVersion $apiVersion `
    -pat $pat -isOnline

$buildDefId = 313
$result = Start-Build -buildDefId $buildDefId -context $ctx
$result


# *********************************************************
# pipeline retention leases
$svr = 'dev.azure.com';
$org = 'daradu';
$projName = 'dawr-demo';
$pat = '***'
$apiVersion = '7.0'

# $apiVersion = '' # '5.1' for Azure DevOps Services | '5.0' for Azure DevOps Server | '4.1' fro TFS 2018 
$ctx = Get-AzureDevOpsContext -protocol https -coreServer $svr -org $org -project $projName -apiVersion $apiVersion `
    -pat $pat -isOnline

# get user for ownerId = "User:<originId>"
$users = Get-Users -context $ctx
$user = $users.value | Where-Object { $_.principalName -eq 'daradu@microsoft.com' } | Select-Object -First 1

# get build leases
$runId = 30764
$leases = Get-BuildLeases -buildId $runId -context $ctx
$leases

# get leases based on various params
$definitionId = 78 # ETSDemo-CI
$ownerId = "Pipeline:$($definitionId)"
$repoId = 'f7d2e7aa-ce81-4607-8dbf-277cd1193320'
$branchName = 'refs/heads/master'
$ownerId = "Branch:$($repoId):$($branchName)"
$ownerId = "User:$($user.originId)"
$runId = 30601
# can use a combination of:
# - definitionId
# - ownerId
# - definitionId + ownerId
# - definitionId + runId
# - definitionId + ownerId + runId
$leases = Get-Leases -context $ctx `
-definitionId $definitionId `
-runId $runId `
-ownerId $ownerId
$leases

# get a single lease
$leaseId = 1505 # 1472
$lease = Get-Lease -leaseId $leaseId -context $ctx
$lease

# add a lease to an existing pipeline, run and owner
# owner can be
# - Pipeline:<pipelineId>
# - Branch:<repoId>:<branchName>
# - User:<userId>, usually originId fro AAD
# - RM - release management
$definitionId = 78 # ETSDemo-CI
$runId = 30764
$daysValid = 10
$ownerId = "User:$($user.originId)" # "Pipeline:$($definitionId)" # "User:$($user.originId)"
$response = Add-Lease -definitionId $definitionId -runId $runId -daysValid $daysValid -ownerId $ownerId -context $ctx
$response

# update lease (only daysValid and protectPipeline)
$leaseId = 1505
$daysValid = 20
$lease = Set-Lease -leaseId $leaseId -daysValid $daysValid -context $ctx
$lease

# delete one or more leases
$leaseIds = '1503,1504'
$response = Remove-Leases -leaseIds $leaseIds -context $ctx
$response

Function HandleEx($ex) {
    Write-Host $ex
    $result = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($result)
    $responseBody = $reader.ReadToEnd()
    Write-Host $responseBody
}


