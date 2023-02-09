# . .\AzureDevOpsContext.ps1
# . .\Get-AzureDevOpsContext.ps1
$context = Get-AzureDevOpsContext -protocol https -coreServer dev.azure.com -org daradu -project dawr-demo -apiVersion 6.0 `
    -pat *** -isOnline

. .\Add-GitRepo.ps1
Add-GitRepo -repoName TenantGTodoApp -context $context

. .\Add-GitRepoStructure.ps1
Add-GitRepoStructure -repoName TenantGTodoApp -upstreamRepoUrl https://daradu@dev.azure.com/daradu/infrastructure/_git/app `
    -customerTenant TenantG -rootFolder C:\Temp -context $context

. .\Sync-GitRepo.ps1
Sync-GitRepo -repoName derivedRepo -customerTenant XYZ -srcDir C:\Temp

. .\Set-WebAppKVAccess.ps1
Set-WebAppKVAccess -rgName CCN-invoicing-app -webAppName ccn-invoicing-app -rgNameKeyVault daradu-demo -keyVaultName ccn-kv

$length = 24
$nonAlphaChars = 5
[System.Web.Security.Membership]::GeneratePassword($length, $nonAlphaChars)

$scriptPath = Split-Path -parent $MyInvocation.MyCommand.Definition
Set-Location $scriptPath
$PSCommandPath
$global:PSScriptRoot

(Get-Variable MyInvocation).Value # -Scope 1

. .\Add-DeployKVRelease.ps1

$kvReleaseDefId = 11
$kvBuildDefId = 31
$kvBuildId = 1060
$description = 'Create Key Vault for TenantG'
$resourceGroup = 'TenantG'
$location = 'North Europe'
$keyVaultName = 'tenantg-kv'
$objectId = '23121eeb-87a6-4ed1-b58b-4d9f249b8b1a'
Add-DeployKVRelease -kvReleaseDefId $kvReleaseDefId -kvBuildDefId $kvBuildDefId -kvBuildId $kvBuildId -description $description -context $context `
    -resourceGroup $resourceGroup -location $location -keyVaultName $keyVaultName -objectId $objectId

. .\Add-StorageQueue.ps1
$rgName = 'meta-demo'
$acctName = 'ivmetademoacct'
$queueName = 'features'
Add-StorageQueue -rgName $rgName -acctName $acctName -queueName $queueName


. .\Add-VarGroupFromCsv.ps1
$varGroupName = 'app-72c4c867-fc2c-46a1-826f-9508ad0374dd'
$csvFilePath = "C:\Sources\environment\var-groups\varGroup.app.csv"
$description = "Test $varGroupName"
Add-VarGroupFromCsv -context $context -varGroupName $varGroupName -csvFilePath $csvFilePath -description $description

. .\Set-WebAppKVAccess.ps1
$rgName = 'TenantG-app-58571f9b-428d-4430-9da1-a54cc2833990'
$rgNameKeyVault = 'TenantG'
$webAppName = 'app-58571f9b-428d-4430-9da1-a54cc2833990-api'
$keyVaultName = 'tenantg-kv'
Set-WebAppKVAccess -rgName $rgName -webAppName $webAppName -rgNameKeyVault $rgNameKeyVault -keyVaultName $keyVaultName

. .\Get-VarGroupVariablesAsCsv.ps1
$groupId = 19 #18 #19
$csvFilePath = "C:\Data\vars.$groupId.csv"
$s = Get-VarGroupVariablesAsCsv -groupId $groupId -context $context -outputCsvFilePath $csvFilePath

. .\Update-VarGroupFromCsv.ps1
$groupId = 19
$varGroupName = 'TenantG-app-58571f9b-428d-4430-9da1-a54cc2833990'
$csvFilePath = "C:\Sources\infrastructure\Pipelines\VarGroups\varGroup.TenantG-app-58571f9b-428d-4430-9da1-a54cc2833990.csv"
$description = $null
Update-VarGroupFromCsv -context $context -groupId $groupId -varGroupName $varGroupName -csvFilePath $csvFilePath -description $description


# *********************************************

Remove-Module AzureDevOps

Import-Module .\AzureDevOps.psm1


$org = 'daradu'
$projName = 'dawr-demo'
$pat = '***'
$context = Get-AzureDevOpsContext -protocol https -coreServer dev.azure.com -org $org -project $projName -apiVersion 6.0 `
    -pat $pat -isOnline

$buildId = 27189
$propertyFilters = 'logs'
$build = Get-Build -buildId $buildId -propertyFilters $propertyFilters -context $context
$build


# . .\Azure\Copy-AzureFile.ps1
Remove-Module Azure

Import-Module .\Azure.psm1
$params = @{
    filePath = "C:\Users\daradu\Pictures\Screenshots\Screenshot.png"
    containerName = 'img'
    rgName = 'dsd'
    stgAccName = 'stgacct1234'
}
Copy-AzureFile @params -overwrite

$buildId = 27189
$fileName = "\$buildId.json"
$filePath = -join ($env:TEMP, $fileName)
$filePath

Remove-Module AzureDevOps
Import-Module .\AzureDevOps.psm1
$org = 'daradu'
$projName = 'COPI-S'
$pat = '***'
$context = Get-AzureDevOpsContext -protocol https -coreServer dev.azure.com -org $org -project $projName -apiVersion 6.0 `
    -pat $pat -isOnline
$ids = '10'
$wis = Get-WorkItems -context $context
$wis


#### Permissions

$descriptor = Get-ProjectDescriptor -projectName $context.project -context $context
$descriptor

$projects = Get-Projects -context $context
$projects | ConvertTo-Json -Depth 10 > "C:\Data\AWE\Permissions\projects.json"

$project = Get-Project -projectName $context.project -context $context
$project
 
$groupDescriptor = 'Microsoft.TeamFoundation.Identity;S-1-9-1551374245-4195559986-1572548169-2940938664-2294232867-1-117161741-2968177997-2332442835-974108426'
$descriptor = Get-DescriptorFromGroupDescriptor -groupDescriptor $groupDescriptor
#Microsoft.TeamFoundation.Identity;
$subjectDescriptor = 'Microsoft.TeamFoundation.Identity;S-1-9-1551374245-4195559986-1572548169-2940938664-2294232867-1-117161741-2968177997-2332442835-974108426'
$identity = Get-IdentityBySubjectDescriptor -subjectDescriptor $descriptor -context $context


$namespaceId = "52d39943-cb85-4d7f-8fa8-c6baac873819" # Project
$token = "`$PROJECT:vstfs:///Classification/TeamProject/" + $project.id
$url = "https://dev.azure.com/" + $context.org + "/_apis/accesscontrollists/" + $namespaceId + "?token=" + $token + "&api-version=6.0"
$url
$headers = @{ Authorization = "Basic $($context.base64AuthInfo)" } 
$headers

Invoke-RestMethod -Uri $url -Headers $headers
$r




$filterValue = 'Project Collection Valid Users'
$url = "https://vssps.dev.azure.com/" + $context.org + "/_apis/identities?searchFilter=General&filterValue=" + $filterValue + "&queryMembership=None&api-version=6.0"
$url


$url = "https://vsaex.dev.azure.com/" + $context.org + "/_apis/groupentitlements?api-version=6.0-preview.1"
$url

$url = "https://vsaex.dev.azure.com/" + $context.org + "/_apis/userentitlements?api-version=6.0-preview.3"
$url


$reports = Get-PermissionsReports -context $context
$reports
$reportId = '480db92b-d4ba-466f-89ee-976634bf30f1' # deleted
$reportId = 'd08eb6d9-f493-4e50-8ed1-e307ca0e7a52'
$reportId = '9acb4b5b-1cba-4c14-89fd-101a4141ef82'
$report = Get-PermissionsReport -reportId $reportId -context $context
$report.reportStatus



$reportName = 'PermissionsReport-' + (Get-Date -Format "yyyyMMdd_HHmmss")
$descriptors = @('aad.MWQ5MjMzODktYzU4Zi03MTZkLTgxOWYtMDI4NjI5YzBiZmQ5') # daradu@microsoft.com
$resources = @(@{ resourceId = "dawr-demo"; resourceName = 'dawr-demo'; resourceType = 'projectGit'})
$result = Add-PermissionsReport -reportName $reportName -descriptors $descriptors -resources $resources -context $context
$result

$userEntitlements = Get-UserEntitlements -context $context
$userEntitlements | ConvertTo-Json -Depth 10 > C:\Data\AWE\Permissions\userentitlements.json
$groupEntitlements = Get-GroupEntitlements -context $context
$groupEntitlements | ConvertTo-Json -Depth 10 > C:\Data\AWE\Permissions\groupentitlements.json

$groups = Get-Groups -projectName $context.project -context $context
$groups | ConvertTo-Json -Depth 10 > C:\Data\AWE\Permissions\dawr-demo.groups.json

$users = Get-Users -context $context
$users | ConvertTo-Json -Depth 10 > C:\Data\AWE\Permissions\users.json

$allUsers = Get-AllUsers -context $context
$allUsers

$projectName = 'dawr-demo' # $null
$allGroups = Get-AllGroups -projectName $projectName -context $context
$allGroups


$principalName = 'radudanielro@yahoo.com' # 'daradu@microsoft.com'
$usrs = $allUsers.value | Where-Object { $_.principalName -eq $principalName }
$descriptor = $usrs[0].descriptor

$principalName = '[dawr-demo]\Team 3'
$grps = $allGroups.value | Where-Object { $_.principalName -eq $principalName }
$descriptor = $grps[0].descriptor

$proj = Get-Project -projectName $projName -context $context
$proj

<#
Although the documentation specifies 'collection', 'project', 'repo', 'ref', 'release', 'tfvc' or 'projectGit', attempts to use 'collection' or 'project' failed with the following error:
Permissions report request should contain one Resource of type 'Repo', 'Ref', 'Release', 'Tfvc' or 'ProjectGit'.
See: https://docs.microsoft.com/en-us/rest/api/azure/devops/permissionsreport/permissions%20report/create?view=azure-devops-rest-6.0
#>
$reportName = 'PermissionsReport-' + (Get-Date -Format "yyyyMMdd_HHmmss")
$descriptors = @($descriptor)
$resource = @{ resourceId = ''; resourceName = ''; resourceType = ''}
# Permissions for all repositories for a project; resourceName = <project>
$resource = @{ resourceId = "dawr-demo"; resourceName = 'dawr-demo'; resourceType = 'projectGit'}
# Permissions for a repository branch; resourceName = <project>/<repo>/<branch>
# $resource = @{ resourceId = 'dawr-demo/B2CApplications/refs/heads/main'; resourceName = 'dawr-demo/B2CApplications/refs/heads/main'; resourceType = 'ref'}
# Permissions for a repository; resourceName = <project>/<repo>
# $resource = @{ resourceId = 'dawr-demo/B2CApplications'; resourceName = 'dawr-demo/B2CApplications'; resourceType = 'repo'}
# Permissions for collection - FAILED 
# $resource = @{ resourceId = 'daradu'; resourceName = 'daradu'; resourceType = 'collection'}
# Permissions for project - FAILED 
# $resource = @{ resourceId = 'dawr-demo'; resourceName = 'dawr-demo'; resourceType = 'project'}
# Permissions for releases; resourceId = <project GUID>; resourceName = <project>; resourceType = release 
$resource = @{ resourceId = $proj.id; resourceName = 'dawr-demo'; resourceType = 'release'}
# Permissions for a specific release; resourceId = <project GUID>; resourceName = <project>; resourceType = release 
# $resource = @{ resourceId = "$($proj.id)/DB-001"; resourceName = "$($proj.id)/DB-001"; resourceType = 'release'}
$result = Add-PermissionsReport -reportName $reportName -descriptors $descriptors -resource $resource -context $context
$result

$reportId = '9acb4b5b-1cba-4c14-89fd-101a4141ef82'
$report = Get-PermissionsReportDownload -reportId $reportId -context $context
$path = "C:\Data\AWE\Permissions\" + $reportName.Replace(":", "") + ".json"
$report > $path


$groupName = 'Team 3'
$namespaceName = 'ReleaseManagement' # 'DashboardsPrivileges' # 'Project'
$securityToken = $proj.id + '/16' # DB-001 # '$PROJECT'
$permissions = Get-GroupPermissionAzDevOpsCli -groupName $groupName -namespaceName $namespaceName -securityToken $securityToken -context $context 
$permissions

$permissions > "C:\Data\AWE\Permissions\group.ReleaseManagement.16.perms.json"



$userName = 'radudanielro@yahoo.com' # 'daradu@microsoft.com'
$namespaceName = 'Identity' # 'Project' # 'Git Repositories' # 'ReleaseManagement' # 'DashboardsPrivileges' # 'Project'
# $ns = Get-SecurityNamespace -namespaceName $namespaceName -context $context
$securityToken = $proj.id # + '/16' # DB-001 # '$PROJECT'
$permissions = Get-UserPermissionAzDevOpsCli -userName $userName -namespaceName $namespaceName -securityToken $securityToken -context $context 
$permissions > C:\Data\DAFF\user_perms.json

$org = 'daradu'
$projName = 'infrastructure'
$context = Get-AzureDevOpsContext -protocol https -coreServer dev.azure.com -org $org -project $projName -apiVersion 6.0 `
    -pat $pat -isOnline

$proj = Get-Project -projectName $projName -context $context
$repoName = 'infrastructure'
$repo = Get-GitRepo -repoName $repoName -context $context
$userName = 'radudanielro@yahoo.com' # 'daradu@microsoft.com'
$namespaceName = 'Git Repositories' # 'ReleaseManagement' # 'DashboardsPrivileges' # 'Project'
# $ns = Get-SecurityNamespace -namespaceName $namespaceName -context $context
$securityToken = 'repoV2/' + $proj.id + '/' + $repo.id # DB-001 # '$PROJECT'
$permissions = Get-UserPermissionAzDevOpsCli -userName $userName -namespaceName $namespaceName -securityToken $securityToken -context $context 
$groupName = 'Infrastructure-Repo'
$permissions = Get-GroupPermissionAzDevOpsCli -groupName $groupName -namespaceName $namespaceName -securityToken $securityToken -context $context 
$permissions

az devops security permission list --id $ns.namespaceId --subject $userName --scope 

$permissions > "C:\Data\AWE\Permissions\group.Git Repo.infrastructure.perms.json"


# *********************************************
Remove-Module AzureDevOps
Import-Module .\AzureDevOps.psm1


$org = 'daradu'
$projName = 'dawr-demo'
$pat = '***'
$context = Get-AzureDevOpsContext -protocol https -coreServer dev.azure.com -org $org -project $projName -apiVersion 6.0 `
    -pat $pat -isOnline

# https://docs.microsoft.com/en-us/rest/api/azure/devops/wit/fields/list?view=azure-devops-rest-6.0
$fields = Get-Fields -context $context
$fields.value | Where-Object { $_.referenceName.StartsWith("Custom.") }
$fields.value | Select-Object { $_.referenceName }

# https://docs.microsoft.com/en-us/rest/api/azure/devops/wit/fields/get?view=azure-devops-rest-6.0
$fieldName = 'CustomField'
$field = Get-Field -fieldNameOrRefName $fieldName -context $context
$field

# https://docs.microsoft.com/en-us/rest/api/azure/devops/processes/fields/list?view=azure-devops-rest-6.1
$processes = Get-Processes -context $context
$customAgileProcess = $processes.value | Where-Object { $_.name -eq 'Custom Agile' }
$customAgileProcess

# https://docs.microsoft.com/en-us/rest/api/azure/devops/processes/work-item-types/list?view=azure-devops-rest-6.1
$wits = Get-ProcessWITs -processId $customAgileProcess.id -context $context
$wits

# https://docs.microsoft.com/en-us/rest/api/azure/devops/processes/fields/list?view=azure-devops-rest-6.1
$witRefName = 'MyAgile.Bug'
$fields = Get-ProcessWITFields -processId $customAgileProcess.id -witRefName $witRefName -context $context
$fields

# https://docs.microsoft.com/en-us/rest/api/azure/devops/processes/fields/get?view=azure-devops-rest-6.1
$witRefName = 'MyAgile.Bug'
$fieldRefName = 'Custom.SquashDate'
$field = Get-ProcessWITField -processId $customAgileProcess.id -witRefName $witRefName -fieldRefName $fieldRefName -context $context
$field


# https://docs.microsoft.com/en-us/rest/api/azure/devops/wit/fields/create?view=azure-devops-rest-6.1
$name = 'F' * 128
$name
$type = 'integer'
$newField = Add-Field -name $name -type $type -canSortBy -context $context
$newField

# https://docs.microsoft.com/en-us/rest/api/azure/devops/processes/fields/add?view=azure-devops-rest-6.1
$referenceName = "Custom.$($name)"
$newProcessWITField = Add-ProcessWITField -processId $customAgileProcess.id -witRefName $witRefName -referenceName $referenceName -allowedValues @() -context $context
$newProcessWITField


$context
$groups = Get-Groups -projectName $context.project -context $context
$groups.value | Where-Object { $_.principalName -like '*\T' }

$url = "https://dev.azure.com/$($context.org)/$($context.project)/_api/_identity/AddTeamAdmins?api-version=5.1-preview.1"
$teamId = 'ee80929e-6d3e-4ba8-9dcf-664db6b7a2d8'
$userId = 'radudanielro@yahoo.com'
$data = @{ teamId = $teamId; newUsersJson = @(); existingUsersJson = @($userId)} | ConvertTo-Json
$response = Invoke-WebRequest -Uri $url -Headers @{ Authorization = "Basic $($context.base64AuthInfo)" } -Method Post
$response


$users = Get-Users -context $context
$users.value | Where-Object { $_.principalName -like '*radu*' }
$users.value | Where-Object { $_.origin -like 'vsts' }


$nsId = '101eae8c-1709-47f9-b228-0e476c35b3ba' # DistributedTask
$subject = 'daradu@microsoft.com' # 'radudanielro@yahoo.com' 
$perms = $(az devops security permission list --id $nsId --recurse) # --subject $subject --recurse)
$perms > C:\Data\DistributesTask.daradu.perms.json


$userName = 'daradu@microsoft.com' # 'radudanielro@yahoo.com'
$response = Remove-UserEntitlements -userName $userName -context $context
$response


$users = Get-Users -context $context
$users.value > C:\Data\DAFF\users.txt


$entitlementId = 'fd630bd5-1b88-6f79-b378-ad7b66a0c79c'
$data = @($entitlementId) | ConvertTo-Json 
$data


$entitlements = Get-UserEntitlements -context $context
$entitlements.members[0]
$entitlements.members[1]


