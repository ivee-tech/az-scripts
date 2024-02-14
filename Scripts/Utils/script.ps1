. .\base64.ps1

$data = "Hello World"
$b64 = base64 $data
$b64
$decoded = base64 $b64 -d
$decoded

