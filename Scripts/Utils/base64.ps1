Function base64
{
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$data,
    [Parameter()][switch]$d
)

if($d.IsPresent) {
    $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($data))
    $decoded
    }
else {
    $encoded = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($data))
    return $encoded
}

}
