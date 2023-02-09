Function Add-SqlServerFirewallRule {
[CmdletBinding(DefaultParameterSetName = 'None')]
param
(
  [Parameter(Mandatory = $true)][string] $dbServerName,
  [Parameter(Mandatory = $true)][string] $rgName,
  [string] $ipAddress = '',
  [string] $firewallRuleName = "AzureWebAppFirewall"
)

if([string]::IsNullOrEmpty($ipAddress)) {
    $ip = (New-Object net.webclient).downloadstring("http://checkip.dyndns.com") -replace "[^\d\.]" # get IP
}
else {
    $ip = $ipAddress
}
    New-AzSqlServerFirewallRule -ResourceGroupName $rgName -ServerName $dbServerName -FirewallRuleName $firewallRuleName `
        -StartIPAddress $ip -EndIPAddress $ip

}
