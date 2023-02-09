class PermissionsReportResource {
    [string]$resourceId
    [string]$resourceName
    [ValidateSet('collection', 'project', 'projectGit', 'ref', 'release', 'repo', 'tfvc')]
    [string]$resourceType 
}
