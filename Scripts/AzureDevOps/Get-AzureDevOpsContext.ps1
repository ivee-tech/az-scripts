# . .\AzureDevOpsContext.ps1

Function Get-AzureDevOpsContext {
    [CmdletBinding()]
    param(
      [ValidateNotNullOrEmpty()]
      [Parameter(Mandatory = $true)][string]$protocol,
      [Parameter(Mandatory = $true)][string]$coreServer,
      [Parameter(Mandatory = $true)][string]$org,
      [Parameter(Mandatory = $true)][string]$project,
      [Parameter(Mandatory = $true)][string]$apiVersion,
      [switch]$isOnline,
      [Parameter()][string]$pat
    )
    
  
    $orgBaseUrl = $protocol + '://' + $coreServer + '/' + $org + '/_apis'
    $orgUrl = $protocol + '://' + $coreServer + '/' + $org 
    $projectBaseUrl = $protocol + '://' + $coreServer + '/' + $org + '/' + $project + '/_apis'
    $projectUrl = $protocol + '://' + $coreServer + '/' + $org + '/' + $project
    
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($org):$pat"))
  
    # $r = [AzureDevOpsContext]::new()
    $r = New-Object AzureDevOpsContext

    $r.orgBaseUrl = $orgBaseUrl
    $r.orgUrl = $orgUrl
    $r.projectBaseUrl = $projectBaseUrl
    $r.projectUrl = $projectUrl
    $r.base64AuthInfo = $base64AuthInfo
    $r.protocol = $protocol
    $r.coreServer = $coreServer
    $r.org = $org
    $r.project = $project
    $r.apiVersion = $apiVersion
    $r.isOnline = $isOnline
    $r.pat = $pat
  
    return $r
  }
  