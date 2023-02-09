$org = 'daradu'
$fullOrg = "https://dev.azure.com/$org"
$project = 'dawr-demo'
az devops security permission namespace list --org $fullOrg > security-namespaces-full.json # --output table
az devops security permission --help

# see security-namespaces.json
$wi = @{
    "name" = "Plan"
    "namespaceId" = "bed337f8-e5f3-4fb9-80da-81e17d06e7a8"
}
az devops security permission namespace show --namespace-id $wi.namespaceId

$subject = 'Microsoft.IdentityModel.Claims.ClaimsIdentity;322a13fa-bb5d-492e-af4b-29a888bf3723\daradu@microsoft.com' # '[dawr-demo]\Project Administrators' # 'daradu@microsoft.com'
az devops security permission list --id $wi.namespaceId --subject $subject --recurse
