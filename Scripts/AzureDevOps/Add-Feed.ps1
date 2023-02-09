# . .\AzureDevOpsContext.ps1
# . .\Get-Feed.ps1

Function Add-Feed
{
    [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)][string]$name,
    [Parameter(Mandatory=$true)][string]$description,
    [Parameter()][switch]$orgLevel,
    [Parameter()][switch]$addPublicUpstreamSources,
    [Parameter()][switch]$addInternalUpstreamSource,
    [Parameter()][string]$internalFeedId,
    [Parameter()][switch]$orgLevelInternal,
    [Parameter(Mandatory=$true)][string]$orgId,
    [Parameter()][string]$projectId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$contentType = 'application/json'
$v = $context.apiVersion + '-preview.1'

if($addInternalUpstreamSource) {
    if($orgLevelInternal) {
        $internalFeed = Get-Feed -feedId $internalFeedId -orgLevel -context $context
    }
    else {
        $internalFeed = Get-Feed -feedId $internalFeedId -context $context
    }
}

if($orgLevel) {
    $feedsUrl = $context.orgBaseUrl + '/packaging/feeds?api-version=' + $v
}
else {
    $feedsUrl = $context.projectBaseUrl + '/packaging/feeds?api-version=' + $v
}
Write-Host $feedsUrl

$feed = @{
    name = $name;
    description = $description;
    upstreamSources = @();
}

if($addPublicUpstreamSources) {
    $feed.upstreamSources = @(
        @{
            name = "NuGet Gallery";
            protocol = "nuget";
            location = "https://api.nuget.org/v3/index.json";
            displayLocation = "https://api.nuget.org/v3/index.json";
            upstreamSourceType = "public";
        },
        @{
            name = "npmjs";
            protocol = "npm";
            location = "https://registry.npmjs.org/";
            displayLocation = "https://registry.npmjs.org/";
            upstreamSourceType = "public";
        },
        @{
            name = "Maven Central";
            protocol = "Maven";
            location = "https://repo.maven.apache.org/maven2/";
            displayLocation = "https://repo.maven.apache.org/maven2/";
            upstreamSourceType = "public";
        }
     )
}

if($addInternalUpstreamSource) {
    $internalFeed.upstreamSources | ForEach-Object {
        $us = $_
        $displayLoc = if($orgLevelInternal) { "azure-feed://$($context.org)/$internalFeedId@Local" } else { "azure-feed://$($context.org)/$($context.project)/$internalFeedId@Local" } 
        $loc = if($orgLevelInternal) { "azure-feed://$orgId/$($internalFeed.id)@$($internalFeed.defaultViewId)" } else { "azure-feed://$orgId/$projectId/$($internalFeed.id)@$($internalFeed.defaultViewId)" } 
        $feed.upstreamSources += @{
            name = "$($internalFeed.name)@Local";
            location = $loc;
            displayLocation = $displayLoc;
            protocol = $us.protocol;
            internalUpstreamCollectionId = $orgId;
            internalUpstreamFeedId = $internalFeed.id;
            internalUpstreamViewId = $internalFeed.defaultViewId;
            upstreamSourceType = "internal";
        }
    }
}

$data = ConvertTo-Json -InputObject $feed -Depth 100
Write-Host $data

if($context.isOnline) {
    $feed = Invoke-RestMethod -Headers @{Authorization="Basic $($context.base64AuthInfo)"} -Uri $feedsUrl -Method Post -Body $data -ContentType $contentType
}
else {
    $feed = Invoke-RestMethod -Uri $feedsUrl -UseDefaultCredentials -Method Post -Body $data -ContentType $contentType
}

return $feed

}