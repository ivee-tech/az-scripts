# . .\AzureDevOpsContext.ps1

Function Get-SecurityNamespace {
    [CmdletBinding()]
param(
    [Parameter()][string]$namespaceName,
    [Parameter()][string]$namespaceId,
    [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
)

$securityNamespaces = Get-SecurityNamespaces -context $context

if(![string]::IsNullOrEmpty($namespaceName)) {
    $securityNamespace = $securityNamespaces.value | Where-Object { $_.name -eq $namespaceName }
    return $securityNamespace
}

if(![string]::IsNullOrEmpty($namespaceId)) {
    $securityNamespace = $securityNamespaces.value | Where-Object { $_.namespaceId -eq $namespaceId }
    return $securityNamespace
}

return $null 

}
