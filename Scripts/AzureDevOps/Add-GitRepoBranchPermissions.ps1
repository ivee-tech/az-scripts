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

