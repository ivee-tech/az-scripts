$appName = '<app name>'
$daysExpiry = 7
$monthsRotate = 3
$endDate = (Get-Date).AddMonths($monthsRotate).ToString('yyyy-MM-dd')

$appId = $(az ad app list --filter "displayName eq '$appName'" --query "[0].appId" -o tsv)
$appId

$cred = $(az ad app credential list --id $appId --query "[0]") | ConvertFrom-Json
Write-Host "Current credential for app $($appName):"
$cred
$d = $(Get-Date).AddDays($daysExpiry)
if ($cred.endDateTime -lt $d) {
    az ad app credential reset --id $appId --end-date $endDate
    Write-Host "Secret rotated for $appName, end date set to $endDate"
}
