<#
This script generates random data to be securely sent to an Azure event hub.
It generates up to 100 requests for one execution.
The event hub Url has the following pattern:
https://$ns.servicebus.windows.net/$path/partitions/$partitionId/messages
where
- $ns - Event Hub namesapce
- $path - Event Hub instance path inside the namespace
- $partitionId - Event Hub partition, in this example a random number between 0 and 3
Note: provide your own values for the variables (resource group, Event Hub namespace, Event Hub path).
For the Authorization header generate a Shared Access Signature (SAS) based on the Event Hub namespace access key.

This script can be included in a container (see Dockerfile definition).
The following commands can be used to build the image, run the container, and scale local execution using docker compose:
docker build -t evhub-test:latest .
docker run evhub-test:latest
docker-compose up --scale evhub-test=10
docker-compose down
#>
$rg = 'AAC'
$ns = 'aac-evhub'
$path = 'aac-evhub-uss'
[Reflection.Assembly]::LoadWithPartialName("System.Web")| out-null
$URI="$ns.servicebus.windows.net/$path"
$Access_Policy_Name = 'RootManageSharedAccessKey'
$Access_Policy_Key = '***' # use the event hub namespace access key
#Token expires now+3000
$Expires=([DateTimeOffset]::Now.ToUnixTimeSeconds())+3000
$SignatureString=[System.Web.HttpUtility]::UrlEncode($URI)+ "`n" + [string]$Expires
$HMAC = New-Object System.Security.Cryptography.HMACSHA256
$HMAC.key = [Text.Encoding]::ASCII.GetBytes($Access_Policy_Key)
$Signature = $HMAC.ComputeHash([Text.Encoding]::ASCII.GetBytes($SignatureString))
$Signature = [Convert]::ToBase64String($Signature)
$SASToken = "SharedAccessSignature sr=" + [System.Web.HttpUtility]::UrlEncode($URI) + "&sig=" + [System.Web.HttpUtility]::UrlEncode($Signature) + "&se=" + $Expires + "&skn=" + $Access_Policy_Name
$SASToken

$method = "POST"
$url = "https://$ns.servicebus.windows.net/$path/messages"
$signature = $SASToken
$headers = @{
    "Authorization"=$signature;
    "Content-Type"="application/atom+xml;type=entry;charset=utf-8";
}
$sessionId = [System.Guid]::NewGuid()
$partitionId = Get-Random -Minimum 0 -Maximum 3
$url = "https://$ns.servicebus.windows.net/$path/partitions/$partitionId/messages"
Write-Host $url

$n = Get-Random -Minimum 1 -Maximum 100
Write-Host "Parallel requests: $n"
$data = @()
@(1..$n) | ForEach-Object {
    $sync = Get-Random -Minimum 0 -Maximum 1000
    $createAt = Get-Date -Format 'o'
    $deviceId = [System.Guid]::NewGuid().ToString().Replace("-", "").Substring(0, 16)
    $data += @{ deviceId = $deviceId; createAt = $createAt; sync = $sync; sessionId = $sessionId; inSessionDuration = 1 }
    $body = $data | ConvertTo-Json -Depth 2
    Write-Host $body
    try {
        Invoke-RestMethod -Uri $url -Method $method -Headers $headers -Body $body -ContentType 'application/json'
    }
    catch {
        Write-Host "Error: $_"
    }
}

<#
$data | ForEach-Object -Parallel {
    $body = $using:data | ConvertTo-Json -Depth 2
    try {
        Invoke-RestMethod -Uri $using:url -Method $using:method -Headers $using:headers -Body $body -ContentType 'application/json'
    }
    catch {
        Write-Host "Error: $_"
    }
}
#>

<#
docker build -t evhub-test:latest .
docker run evhub-test:latest
docker-compose up --scale evhub-test=10
docker-compose down
#>
