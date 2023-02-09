Function Remove-SqlServerFirewallRule {
[CmdletBinding(DefaultParameterSetName = 'None')]
param
(
  [Parameter(Mandatory = $true)][string] $dbServerName,
  [Parameter(Mandatory = $true)][string] $rgName,
  [string] $firewallRuleName = "AzureWebAppFirewall"
)

Remove-AzSqlServerFirewallRule -ResourceGroupName $rgName -ServerName $dbServerName -FirewallRuleName $firewallRuleName

}
