
BeforeAll { 
    function Get-Planet ([string]$Name = '*') {
        $planets = @(
            @{ Name = 'Mercury' }
            @{ Name = 'Venus'   }
            @{ Name = 'Earth'   }
            @{ Name = 'Mars'    }
            @{ Name = 'Jupiter' }
            @{ Name = 'Saturn'  }
            @{ Name = 'Uranus'  }
            @{ Name = 'Neptune' }
        ) | ForEach-Object { [PSCustomObject] $_ }

        $planets | Where-Object { $_.Name -like $Name }
    }
}

Describe 'Get-Planet' {

    It 'Given no parameters, it lists all 8 planets' {
        $allPlanets = Get-Planet
        $allPlanets.Count | Should -Be 8
    }
}

Describe 'Mock-Get-ChildItem' {
    It 'Given $$env:Temp should return log-any.log' {
        Mock Get-ChildItem { return @{FullName = "log-any.log"} } -ParameterFilter { $Path -and $Path.StartsWith($env:temp) }
        $r = MyGetChildItem -path $env:TEMP
        $expectedName = "log-any.log"
        Assert-MockCalled Get-ChildItem 
        $r.FullName | Should -Be $expectedName
    }
}

Describe 'Mock-Invoke-RestMethod' {
    It 'Given the show my IP url, it should return localhost IP' {
        Mock Invoke-RestMethod { return "127.0.0.1" } -ParameterFilter { $Uri -and $Uri.ToString().StartsWith("https://ifconfig.me") }
        $r = GetMyIp
        $expectedIP = "127.0.0.1"
        Assert-MockCalled Invoke-RestMethod 
        $r | Should -Be $expectedIP
    }
}


