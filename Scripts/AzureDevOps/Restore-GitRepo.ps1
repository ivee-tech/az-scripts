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
