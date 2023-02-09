$endpoint1 = 'https://web-app-sess.azurewebsites.net/'
$endpoint2 = 'https://web-app-sess.azurewebsites.net/About'

$n = Get-Random -Minimum 1 -Maximum 100
Write-Output "Number of events: $n"
@(1..$n) | ForEach-Object {
    try {
        $r = Invoke-WebRequest -Uri $endpoint1  -SessionVariable 'Session'       
        Write-Output "Home: " $r.Headers["X-Sess-Data"]
        Start-Sleep -Seconds 2
        $r = Invoke-WebRequest -Uri $endpoint2 -WebSession $Session
        Write-Output "About: " $r.Headers["X-Sess-Data"]
    }
    catch {
        Write-Output "Error: $_"
    }
}

<#
docker build -t web-app-sess-test:latest .
docker run web-app-sess-test:latest
docker-compose up --scale web-app-sess-test=10
docker-compose down
#>
