# param(
#     [string]$rgName,
#     [string]$appName
# )

Describe "Test WebApp Deployment on $rgName" {

    BeforeAll {
        $rgName = "__rgName__"
        $appName = "__appName__"
        $app = Get-AzWebApp -ResourceGroupName $rgName -Name $appName
    }
    
    It "Given webapp $appName should be running" {
        $expected = 'Running'
        $app.State | Should -Be $expected
    }
    
    It "Given webapp $appName should be in Australia East" {
        $expected = 'Australia East'
        $app.Location | Should -Be $expected
    }
    
    It "Given webapp $appName should be hosted in azurewebsites.net" {
        $expected = "$appName.azurewebsites.net"
        $app.DefaultHostName | Should -Be $expected
    }
}