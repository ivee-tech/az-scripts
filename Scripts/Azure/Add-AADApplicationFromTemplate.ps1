Function Add-AADApplicationFromTemplate
{
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$displayName,
    [Parameter(Mandatory=$true)][string[]]$redirectUris,
    [Parameter(Mandatory=$true)][string]$templateAppObjectId,
    [Parameter(Mandatory=$true)][string]$repoRootDir,
    [Parameter(Mandatory=$true)][string]$repoName,
    [Parameter(Mandatory=$true)][string]$repoUrl,
    [Parameter(Mandatory=$true)][string]$accessToken,
    [Parameter()][switch]$addToSourceControl
)

try {

$location = Get-Location

$repoDir = "$repoRootDir\$repoName"
Remove-Item -Path $repoDir -Recurse -Force -ErrorAction SilentlyContinue
git clone $repoUrl $repoDir

Set-Location $repoDir

$templateAppDir = "$repoDir\$templateAppObjectId"

$manifestPath = "$templateAppDir\manifest.json"

$manifestJson = Get-Content -Path $manifestPath -Raw
$appData = ConvertFrom-Json -InputObject $manifestJson
$appData


$appdata.id = $null
$appdata.appid = $null
# $appData.PSObject.properties.Remove('<prop>')
$appData.PSObject.properties.Remove('publisherDomain')

$appData.displayName = $displayName
$appData.web.redirectUris = $redirectUris
$appData

$appData | ConvertTo-Json -Depth 10
$app = Add-AADApplication -appData $appData -accessToken $authResult.access_token

if($addToSourceControl) {
    $appObjectId = $app.id
    $appDir = "$repoDir\$appObjectId"
    New-Item -Path $appDir -ItemType Directory -Force -ErrorAction SilentlyContinue
    $manifestPath = "$appDir\manifest.json"
    $app | ConvertTo-Json -Depth 10 > $manifestPath

    git add $manifestPath
    git commit -m "Added $manifestPath"
    git push
}
Set-Location $location

Write-Output "Application $displayName created successfully. AppId: $($app.appId)"

return $app
}
catch {
    Write-Error "Error creating application $displayName or source control operation. Error: $($_.Exception.Message)" 
}

}