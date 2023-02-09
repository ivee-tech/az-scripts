class AzureDevOpsContext {
    [string]$protocol
    [string]$coreServer
    [string]$org
    [string]$project
    [string]$apiVersion
    [bool]$isOnline
    [string]$pat

    [string]$orgBaseUrl
    [string]$orgUrl
    [string]$projectBaseUrl
    [string]$projectUrl
    [string]$base64AuthInfo
}
