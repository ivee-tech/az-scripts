# . .\AzureDevOpsContext.ps1
# . .\Get-AzureDevOpsContext.ps1
# . .\Get-Users.ps1

Function Get-User
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$userName,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$users = Get-Users -context $context

$user = $users.value | Where-Object { $_.principalName -eq "$userName" }
return $user

}
