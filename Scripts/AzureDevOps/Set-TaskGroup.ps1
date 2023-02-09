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
