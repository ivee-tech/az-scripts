# . .\AzureDevOpsContext.ps1
<#
.SYNOPSIS
    This function returns the list of Azure DevOps projects in an organization.

.DESCRIPTION
    This function returns the list of Azure DevOps projects in an organization, beased on authentication context.
    It works for both Azure DevOps Services and Server.
    Requires ... permissions.

.PARAMETER context
    The parameter context is used to define the value of blah and also blah.

.EXAMPLE

Import-Module .\AzureDevOps.psm1

$org = '{org}'
$projName = 'xyz'
$pat = '***'

# create an Azure DevOps context for AuthN
# . .\Get-AzureDevOpsContext.ps1
$context = Get-AzureDevOpsContext -protocol https -coreServer dev.azure.com -org $org -project $projName -apiVersion 6.0 `
    -pat $pat -isOnline

# get the list of projects
$projects = Get-Projects -context $context

.NOTES
    Author: Dan Radu
    Last Edit: 2020-10-21
    Version 1.0 - initial release of AzureDevOps module

#>
Function Get-Projects
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$projectsApiUrl = $context.orgBaseUrl + '/projects/?api-version=' + $context.apiVersion
Write-Host $projectsApiUrl
if($context.isOnline) {
    $projects = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $projectsApiUrl -Method Get
}
else {
    $projects = Invoke-RestMethod -Uri $projectsApiUrl -Method Get -UseDefaultCredentials
}

return $projects.value

}
