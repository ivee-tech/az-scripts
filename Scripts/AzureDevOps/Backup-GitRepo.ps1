Function Backup-GitRepo {
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory = $true)][string]$backupsPath,
        [Parameter(Mandatory = $true)][string]$repoName,
        [Parameter()][switch]$archive,
        [Parameter(Mandatory = $true)][AzureDevOpsContext]$context
    )


    $orig = Get-Location

    $d = Get-Date -Format "yyyyMMdd_HHmm"
    $repoBackupsPath = [IO.Path]::Combine("$backupsPath", "$($context.org)", "$($context.project)", $repoName)
    $repoBackupPath = Join-Path -Path $repoBackupsPath -ChildPath $d
    if(!(Test-Path $repoBackupPath))
    {
        mkdir $repoBackupPath
    }

    Set-Location $repoBackupPath

    $repoUrl = $context.protocol + "://" + $context.org + "@dev.azure.com/" + $context.org + "/" + $context.project + "/_git/" + $repoName

    git clone --mirror $repoUrl

    if($archive) {
        $zipFilePath = Join-Path -Path $repoBackupPath -ChildPath "$d.zip"
        Compress-Archive -Path $repoBackupPath -DestinationPath $zipFilePath
    }

    Set-Location $orig

    return @{
        repoBackupsPath = $repoBackupsPath;
        repoBackupPath = $repoBackupPath;
        archive = $archive;
        repoUrl = $repoUrl;
        repoName = $repoName;
        zipFileName = if($archive) {"$d.zip"} else {""};
        zipFilePath = if($archive) {$zipFilePath} else {""};
    }
}
