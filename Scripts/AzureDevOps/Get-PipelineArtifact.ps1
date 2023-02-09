# . .\AzureDevOpsContext.ps1

Function Get-PipelineArtifact
{
    [CmdletBinding()]
param(
    [Parameter()][string]$pipelineId,
    [Parameter()][string]$pipelineName,
    [Parameter(Mandatory=$true)][string]$artifactName,
    [Parameter(Mandatory=$true)][string]$runId,
    [Parameter()][switch]$download,
    [Parameter()][string]$outputFilePath,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

if([string]::IsNullOrEmpty(($pipelineId))) {
    $pipeline = Get-BuildDefByName -buildDefName $pipelineName -context $context
    $pipelineId = $pipeline.id
}
$v = $context.apiVersion + '-preview.1'
$artifactUrl = $context.projectBaseUrl + '/pipelines/' + $pipelineId + '/runs/' + $runId + '/artifacts?artifactName=' + $artifactName + '&$expand=signedContent&api-version=' + $v
Write-Host $artifactUrl

if($context.isOnline) {
    $artifact = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $artifactUrl -Method Get
}
else {
    $artifact = Invoke-RestMethod -Uri $artifactUrl -UseDefaultCredentials -Method Get
}

if($download) {
    $downloadUrl = [System.Web.HttpUtility]::UrlDecode($artifact.signedContent.url) 
    Write-Host $downloadUrl
    if($context.isOnline) {
        $artifact = Invoke-WebRequest -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $downloadUrl -Method Get -OutFile $outputFilePath
    }
    else {
        $artifact = Invoke-WebRequest -Uri $downloadUrl -UseDefaultCredentials -Method Get -OutFile $outputFilePath
    }   
}

return $artifact

}