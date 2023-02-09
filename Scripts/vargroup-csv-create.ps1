param(
    [Parameter(Mandatory=$true)][string]$project,
    [Parameter(Mandatory=$true)][string]$pat,
    [Parameter(Mandatory=$true)][string]$varGroupName,
    [Parameter(Mandatory=$true)][string]$csvFilePath,
    [Parameter()][string]$description
)

# . .\AzureDevOpsContext.ps1
. .\Get-AzureDevOpsContext.ps1
$context = Get-AzureDevOpsContext -protocol https -coreServer dev.azure.com -org ivee -project $project -apiVersion 5.1-preview.1 `
    -pat $pat -isOnline

. .\Add-VarGroupFromCsv.ps1
Add-VarGroupFromCsv -context $context -varGroupName $varGroupName -csvFilePath $csvFilePath -description $description
