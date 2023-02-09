param(
    [Parameter(Mandatory=$true)][string]$AZP_URL
    , [Parameter(Mandatory=$true)][string]$AZP_TOKEN
)

if (-not ($AZP_URL)) {
  Write-Error "error: missing AZP_URL parameter"
  exit 1
}

if (-not ($AZP_TOKEN)) {
    Write-Error "error: missing AZP_TOKEN environment variable"
    exit 1
}

New-Item "\azp\agent" -ItemType directory | Out-Null

Set-Location agent

Write-Host "Determining matching Azure Pipelines agent..." -ForegroundColor Cyan

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($AZP_TOKEN)"))
$url = "$($AZP_URL)/_apis/distributedtask/packages/agent?platform=win-x64&`$top=1"
Write-Host $url
$package = Invoke-RestMethod -Headers @{Authorization=("Basic $base64AuthInfo")} $url
$packageUrl = $package[0].Value.downloadUrl

Write-Host $packageUrl

Write-Host "Downloading and installing Azure Pipelines agent..." -ForegroundColor Cyan

$wc = New-Object System.Net.WebClient
$wc.DownloadFile($packageUrl, "$(Get-Location)\agent.zip")

Expand-Archive -Path "agent.zip" -DestinationPath "\azp\agent"

exit 0
