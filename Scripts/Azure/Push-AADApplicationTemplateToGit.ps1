Function Push-AADApplicationTemplateToGit
{
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$appObjectId,
    [Parameter(Mandatory=$true)][string]$repoRootDir,
    [Parameter(Mandatory=$true)][string]$repoName,
    [Parameter(Mandatory=$true)][string]$repoUrl,
    [Parameter(Mandatory=$true)][string]$accessToken
)

try {

    $location = Get-Location

    $repoDir = "$repoRootDir\$repoName"
    Remove-Item -Path $repoDir -Recurse -Force -ErrorAction SilentlyContinue
    git clone $repoUrl $repoDir
    
    Set-Location $repoDir
    
    $appDir = "$repoDir\$appObjectId"
    New-Item -Path $appDir -ItemType Directory -Force -ErrorAction SilentlyContinue
    
    $manifestPath = "$appDir\manifest.json"
    $app = Get-AADApplication -appObjectId $appObjectId -accessToken $authResult.access_token
    
    # $app is an array with two elements, graph Url and app data 
    $app[1] | ConvertTo-Json -Depth 10 > $manifestPath
    
    git add $manifestPath
    git commit -m "Added $manifestPath"
    git push
    
    Set-Location $location

    Write-Output "Application template $($appObjectId) added successfully to git."
    
}
catch {
    Write-Error "Error adding application $($appObjectId) to source control. Error: $($_.Exception.Message)" 
}
}